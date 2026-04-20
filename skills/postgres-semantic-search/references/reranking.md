# Re-ranking Guide

Re-ranking is a two-stage retrieval pattern:

1. **Stage 1:** Fast retrieval (vector/hybrid search) — get 50-100 candidates
2. **Stage 2:** Precise re-ranking — score candidates with a cross-encoder

## Why Re-rank?

| Retrieval | Re-ranker |
|-----------|-----------|
| Bi-encoder (fast) | Cross-encoder (slow, accurate) |
| Single embedding per doc | Compares query + doc together |
| O(1) per doc | O(n) for n candidates |

Cross-encoders partially rediscover a semantic variant of BM25 (attention ≈
soft TF, embedding matrix ≈ semantic IDF), which is why BM25 / hybrid +
cross-encoder works so well together.

## Reranker categories

Rerankers fall into two broad families:

- **API-based** (managed service) — high quality, no infra, pay per query.
  Pick when results must be precise and the latency budget allows it.
- **Self-hosted** (cross-encoder behind your own service) — privacy,
  predictable cost at volume, no vendor lock-in. Pick when you have infra
  and want control.

Ask the user's preference. Check the provider's docs for the current
recommended model — never hard-code a model version guessed from training
data, because model names rotate every 6-12 months.

## Production rules (apply to ANY reranker)

Re-ranking is an *enhancement*, not a *requirement*. Implementation must
follow these rules — the exact code is straightforward:

1. **Return `null` on failure, never throw.** Missing API key, HTTP error
   (including 429), timeout, malformed response → all return `null`. Caller
   falls back to the original retrieval order (semantic / hybrid / RRF).
2. **Always use a timeout.** `AbortSignal.timeout(4000)` or `AbortController`.
   A slow reranker must not hang the search request.
3. **Short-circuit empty inputs.** Return `null` (not empty array) if there
   are no candidates or no API key — the caller shouldn't need to distinguish
   these cases.
4. **Log failures at `warn` level.** Include the provider name and failure
   reason. Never fail the request.

Ask the user's framework/SDK preference before implementing — some stacks
(e.g., Vercel AI SDK, LangChain) have first-class reranker adapters that
handle retry / timeout / fallback for you.

## Calling a reranker

Prefer your framework's reranker adapter — AI SDK, LangChain, LlamaIndex,
and similar stacks ship adapters that already handle timeout, retries, and
fallback. That keeps the code short and provider-agnostic.

If you must call the HTTP API directly, check the provider's docs for the
current request shape (endpoint, body fields, score path). Keep the rules
from the previous section: timeout + null-on-failure, never throw.

## Self-hosting notes

If self-hosting, two things matter more than the rest:

- **Load the model once at startup**, not per request — initialization is
  slow (typically several seconds) because the cross-encoder weights load
  into memory.
- Expose it as a small HTTP service (e.g. `POST /rerank` taking
  `{ query, documents, top_n }`) so the application can call it with the
  same failure-handling rules as any managed reranker.

## Two-stage retrieval pattern

```
Stage 1: BM25 / hybrid search (fast)
  ├─ Get 50-100 candidates via inverted index or HNSW
  └─ O(log n) per query

Stage 2: Cross-encoder rerank (precise)
  ├─ Score each candidate with full query attention
  └─ O(n) for n candidates
```

## When NOT to re-rank

- Real-time autocomplete (latency critical)
- Very large candidate sets (> 100 docs → too slow, pre-filter first)
- Simple exact-match queries (BM25 alone is already optimal)

## Rerankers can regress — benchmark first

Vendor-claimed "+N pp" is usually measured on English, general-domain data. On
multilingual or heavily domain-specific corpora the same reranker can *hurt*
retrieval quality — double-digit Hit@K losses have been observed in production.

Likely causes:

- Reranker trained predominantly on English; cross-encoder attention is less
  calibrated for the target language's morphology.
- Chunks embedded with a contextual prefix (document title + section) already
  saturate relevance — rerank reshuffles near-ties harmfully.
- Eval-set bias: questions LLM-generated from the same chunks as answers favor
  bi-encoder similarity, amplifying apparent rerank regression.

**Rule**: never ship a reranker from a paper or vendor benchmark alone. A/B on
your own eval set (see [evaluation.md](evaluation.md)). Require ≥ +3 pp Hit@5
AND p95 latency within budget before adopting.

## Provider docs

Check the provider's docs for the current recommended model and request
shape (they update these as models rotate). The stable entry points:

- Cohere — <https://docs.cohere.com/docs/rerank>
- Voyage — <https://docs.voyageai.com/reference/reranker-api>
- HuggingFace (open-weight rerankers) — <https://huggingface.co/models?other=reranker>
