# Evaluation & Benchmarking

Vendor and paper benchmarks are usually English and general-domain. They do
not reliably predict performance on multilingual or domain-specific corpora,
so every non-trivial change (reranker, embedding swap, fusion weights, query
rewriter) needs a domain-owned eval set.

## Build an eval set (LLM-generated)

Fastest way to get 200–500 questions without manual labeling:

1. Sample N chunks from the current corpus. Filter to chunks with ≥ ~200
   characters of meaningful text, and restrict to documents still in use.
2. For each chunk, prompt a cheap model (GPT-4o-mini, Claude Haiku):
   *"Generate a natural \[language\] question that this text answers."*
3. Store as CSV: `question, expected_doc_id, expected_chunk_id`.

Rule of thumb: < 50 Q is noise; 200–500 Q is a useful production signal;
> 1000 Q buys little extra discriminative power.

## Metrics

- **Hit@K** for K = 1, 5, 10 — does the expected chunk appear in the top-K?
  Hit@5 is the usual headline.
- **MRR** — mean reciprocal rank of the first correct hit (rewards earlier
  ranks more than Hit@10).
- **Latency p50 / p95** — measure separately. Warm runs and cold runs
  diverge sharply on HNSW; report both or clearly label which you measured.

## Bias warning (read this before trusting numbers)

When questions are LLM-generated from the same chunks that count as the
correct answer, bi-encoder similarity between query and expected chunk is
unnaturally high. This has two consequences:

1. Pure-vector and RRF baselines look better than they will in production.
2. Rerankers and query rewriters look *worse* than they will in production —
   they shuffle candidates that the biased similarity already ranked near-
   optimally.

Mitigations:

- Mix in a smaller set of manually written, live-style questions (≥ 30–50).
- Re-sample chunks periodically — drift in the corpus invalidates the set.
- Compare deltas, not absolute scores, across runs on the same set.

## Adoption thresholds

Use these as defaults when deciding whether a change ships:

| Δ Hit@5 vs. baseline | Interpretation | Action |
|---|---|---|
| < ±1 pp | Noise | Reject |
| 1–3 pp | Marginal | Weigh vs. added latency, cost, complexity |
| ≥ 3 pp | Meaningful | Adopt if p95 latency fits budget |

Same scale works for MRR deltas (use ± 0.01, 0.01–0.03, ≥ 0.03).

## Running the eval

Minimal pseudocode:

```typescript
const results = [];
for (const { question, expected_chunk_id } of evalSet) {
  const t0 = performance.now();
  const hits = await search(question, { limit: 10 });
  const latencyMs = performance.now() - t0;
  const rank = hits.findIndex((h) => h.chunk_id === expected_chunk_id) + 1;
  results.push({ rank, latencyMs });
}

const hitAt = (k: number) =>
  results.filter((r) => r.rank > 0 && r.rank <= k).length / results.length;
const mrr =
  results.reduce((s, r) => s + (r.rank ? 1 / r.rank : 0), 0) / results.length;
```

Always run the cold query first and discard it (HNSW cold-start dominates).
Repeat the set 2–3 times, report the median per-query latency.

## Typical gotchas

- **Chunk-ID type mismatch**: bigint columns come back as string from some
  drivers; use `String(a) === String(b)` when matching ranks.
- **Filtered queries**: if search applies filters (date, category, access),
  apply the same filters when generating the eval set. Otherwise Hit@K
  collapses for reasons unrelated to ranking quality.
- **Warmup cron**: if the production service keeps HNSW warm via a cron,
  do the same in the benchmark — or you are benchmarking a state users
  never see.
