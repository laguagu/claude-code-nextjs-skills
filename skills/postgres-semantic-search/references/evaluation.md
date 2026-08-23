# Evaluation & Benchmarking

## Contents

- [Build an eval set (LLM-generated)](#build-an-eval-set-llm-generated)
- [Use two sets, and expect them to disagree](#use-two-sets-and-expect-them-to-disagree)
- [Metrics](#metrics)
- [Bias warning (read this before trusting numbers)](#bias-warning-read-this-before-trusting-numbers)
- [Adoption thresholds](#adoption-thresholds)
- [Four ways a measurement lies to you](#four-ways-a-measurement-lies-to-you)
- [Running the eval](#running-the-eval)
- [Typical gotchas](#typical-gotchas)

Vendor and paper benchmarks are usually English and general-domain. They do
not reliably predict performance on multilingual or domain-specific corpora,
so every non-trivial change (reranker, embedding swap, fusion weights, query
rewriter) needs a domain-owned eval set.

## Build an eval set (LLM-generated)

Fastest way to get 200–500 questions without manual labeling:

1. Sample N chunks from the current corpus. Filter to chunks with ≥ ~200
   characters of meaningful text, and restrict to documents still in use.
2. For each chunk, prompt the cheapest/fastest model in your provider's current
   lineup (check their docs — model names rotate every few months):
   *"Generate a natural \[language\] question that this text answers."*
3. Store as CSV: `question, expected_doc_id, expected_chunk_id`.

Rule of thumb: < 50 Q is noise; 200–500 Q is a useful production signal;
> 1000 Q buys little extra discriminative power.

## Use two sets, and expect them to disagree

An LLM-generated set is made of well-formed sentences. Real users mostly type
one to three words — in one production log, 93 % of searches were 1–3 words.
Those are different populations, and a change can help one while hurting the
other. Measured examples from a single codebase:

- dropping an over-common word from a short query's keyword text helped the
  short set and *hurt* the long one;
- a cross-encoder reranker did the reverse.

Either set alone would have given the wrong answer once. So keep two:

| Set | Shape | What it is good for |
| --- | --- | --- |
| **Long** | 70–500 generated natural-language questions | broad regression cover; catches global damage |
| **Short** | 15–50 hand-graded domain terms, 1–3 words | the shape users actually type; term-level fixes |

**They also differ in how much noise they carry, and that decides what you can
detect.** A short-query set with no LLM anywhere on the request path is often
fully deterministic — repeated runs agree to three decimals — so a 1 pp move is
real. A long-query set that touches a query rewriter, an intent splitter or a
translation gate can swing ±3 pp between two runs of *identical code*. Measure
your own run-to-run spread once, write it down next to the set, and never
believe a delta smaller than it.

A corollary that catches people out: "no change on the long set" is only
evidence if some query in that set actually exercises the code you changed.
Check. If none does, the result is a fact about the dataset, not a measurement
— still worth running to rule out accidental global damage, but say so plainly
rather than reporting it as neutral.

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

## Four ways a measurement lies to you

Each of these has been observed turning a confident improvement into a
regression, or the reverse.

### 1. An isolated-arm measurement is not a pipeline measurement

Measuring one retrieval arm on its own tells you about that arm, not about
what fusion does with it. A change that made a keyword arm strictly more
precise in isolation (Hit@1 0.357 → 0.371) was a **loss end to end** (Hit@5
0.790 → 0.768 over four runs), because that arm was the only lexical bridge
for queries whose terms could not prefix-match their inflected forms — RRF was
using its noisy tail. Always confirm on the full pipeline before adopting.

### 2. Better retrieval can produce worse answers

If the retrieval feeds an LLM, retrieval metrics are a proxy, not the goal.
Raising top-k from 15 to 30 on one corpus lifted Recall@30 by 5.4 pp and
*lowered* the share of generated claims actually supported by a retrieved
source from 82.1 % to 78.8 %. More context per request meant the model
grounded less of what it said. Where an unsupported claim is worse than a
missed document, the retrieval win is a regression.

Run a judged answer-quality pass before adopting any change that alters how
much text reaches the model — top-k, chunk size, reranking depth.

### 3. An offline sweep predicts ordering, not production numbers

Sweeps run against a re-chunked set, at full precision, without the index. Use
them to rank candidates against each other; do not expect the absolute numbers
to survive the real pipeline. One sweep showed a model gaining 2 pp at full
precision over its quantized form; through the production pipeline the two
found *exactly* the same documents, the quantized one ranked them better, ran
40 % faster and needed a quarter of the memory. The sweep's gap came from the
index and the storage type, not the model weights at all.

### 4. The obvious improvement is usually noise, a regression, or unmeasured

Of three changes that looked clearly right on one project's sweep data, one
was noise, one was a measured regression, and one turned out to depend on a
measurement nobody had made. Budget for that ratio. Three rejected changes with
reasons written down is a better result than three adopted changes with none.

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
