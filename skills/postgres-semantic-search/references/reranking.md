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

Treat specific model names as examples only — they change every 6-12 months.
Check provider docs for the current recommended model in each category.

| Category | Examples (may change — verify) | When to use |
|---|---|---|
| **API — highest quality** | Cohere (rerank-v4/v5 pro), Zerank, Voyage full | Results must be precise; latency budget allows ~300ms-1s |
| **API — lowest latency** | Cohere fast variant, Voyage lite variant | Interactive search with tight latency |
| **Self-hosted multilingual** | BGE-reranker family, Qwen reranker family | Privacy / high volume / no vendor lock-in |
| **Self-hosted lightweight** | Jina Reranker, small cross-encoders | CPU-only deployments |

**Finding the current model:** ask the user which reranker they want, or check
the provider's docs for "recommended" / "latest" model. Do not hard-code a
version number guessed from training data.

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

## Provider API shapes

When implementing a direct `fetch()` call, these are the request shapes.
Endpoints and field names are stable enough to write against; model names
change frequently.

| Provider | Endpoint | Body (key fields) | Response path to score |
|----------|----------|-------------------|------------------------|
| Cohere | `POST https://api.cohere.com/v2/rerank` | `model`, `query`, `documents[]`, `top_n` | `results[].relevance_score` |
| Voyage | `POST https://api.voyageai.com/v1/rerank` | `model`, `query`, `documents[]`, `top_k`, `truncation` | `data[].relevance_score` |
| Zerank | `POST https://api.zeroentropy.dev/v1/rerank` | `model`, `query`, `documents[]` | check provider docs |

Use `Authorization: Bearer <API_KEY>` on all three. Provider SDKs (e.g., the
official `cohere-ai` package) are fine — just ensure timeout + null-on-error
behaviour is preserved.

## Self-hosting

For high-volume or privacy-sensitive workloads, host a cross-encoder behind
a small HTTP service. Key implementation notes:

- **Load the model once at startup**, not per request (model initialization
  is slow, typically several seconds).
- A FastAPI or similar framework with a `POST /rerank` endpoint accepting
  `{ query, documents, top_n }` is standard; the application calls it with
  the same generic wrapper as any other provider (no auth header needed).
- The `sentence-transformers` Python library's `CrossEncoder` class handles
  model loading and `.predict([[query, doc], ...])` scoring.

Provider docs linked below cover the actual model selection.

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

## Provider docs

Check these for current model names, rate limits, and pricing:

- Cohere Rerank: <https://docs.cohere.com/docs/rerank>
- Voyage Rerank: <https://docs.voyageai.com/reference/reranker-api>
- Zerank: <https://docs.zeroentropy.dev>
- Sentence Transformers (self-hosted cross-encoders): <https://www.sbert.net/docs/cross_encoder/usage/usage.html>
- HuggingFace Hub (search "reranker" for open-weight models): <https://huggingface.co/models?other=reranker>
