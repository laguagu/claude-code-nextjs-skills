# Re-ranking Guide

Re-ranking is a two-stage retrieval pattern:

1. **Stage 1:** Fast retrieval (vector/hybrid search) — get 50-100 candidates
2. **Stage 2:** Precise re-ranking — score candidates with a cross-encoder

## Why Re-rank?

| Retrieval | Re-ranker |
|-----------|-----------|
| Bi-encoder (fast) | Cross-encoder (slow, accurate) |
| Single embedding per doc | Compares query+doc together |
| O(1) per doc | O(n) for n candidates |

## API services

| Service | Latency (30 docs) | Quality | Languages |
|---------|-------------------|---------|-----------|
| Cohere Rerank v4.0-pro | ~300ms | Best | 100+ |
| Cohere Rerank v4.0-fast | ~150ms | Excellent | 100+ |
| Zerank 2 | ~100ms | Best | 100+ |
| Voyage Rerank 2.5 | ~1200ms | Excellent | 100+ |
| Voyage Rerank 2.5-lite | ~600ms | Very Good | 100+ |

> Latencies are wall-clock observations from a real EU workload. Benchmark in
> your own region. Always check provider docs for current pricing and rate limits.

## Open-source models (self-host)

| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| Qwen3-Reranker-8B | 8B | Slow | Excellent |
| Qwen3-Reranker-4B | 4B | Medium | Very Good |
| Qwen3-Reranker-0.6B | 0.6B | Fast | Good |
| bge-reranker-v2-m3 | 560M | Fast | Very Good (multilingual) |
| Jina Reranker v2 | 278M | Fast | Good (lightweight) |

## Production pattern (apply to ANY reranker)

Re-ranking is an *enhancement*, not a *requirement*. A failed call must not
break search — fall back to original retrieval order.

```typescript
interface RerankResult { id: number; score: number }

async function rerank(
  query: string,
  candidates: { id: number; text: string }[],
  topK = 10,
): Promise<RerankResult[] | null> {
  const apiKey = process.env.RERANKER_API_KEY;
  if (!apiKey || candidates.length === 0) return null;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 4_000);

  try {
    const resp = await fetch(RERANKER_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({ query, documents: candidates.map(c => c.text), top_k: topK }),
      signal: controller.signal,
    });
    if (!resp.ok) {
      console.warn(`[rerank] HTTP ${resp.status}`);
      return null;
    }
    const json = await resp.json();
    return json.data.map((r: { index: number; relevance_score: number }) => ({
      id: candidates[r.index].id,
      score: r.relevance_score,
    }));
  } catch (e) {
    console.warn(`[rerank] ${(e as Error).message}`);
    return null;
  } finally {
    clearTimeout(timer);
  }
}

// Caller falls back to original order on null
const reranked = await rerank(query, candidates, 10);
const final = reranked
  ? reranked.map(r => candidates.find(c => c.id === r.id)!).filter(Boolean)
  : candidates.slice(0, 10);
```

**Why every wrapper needs this**: API outages, rate limits (429), slow
responses (> 4s timeout), missing keys in dev — all should silently degrade
to original RRF/vector order, never throw.

## Provider-specific notes

Adapt the generic wrapper above by swapping URL + body shape per provider:

| Provider | Endpoint | Body shape (key fields) | Docs |
|----------|----------|-------------------------|------|
| Cohere | `https://api.cohere.com/v2/rerank` | `model`, `query`, `documents` (strings), `top_n` | [docs.cohere.com/docs/rerank](https://docs.cohere.com/docs/rerank) |
| Voyage | `https://api.voyageai.com/v1/rerank` | `model`, `query`, `documents` (strings, ≤4000 chars), `top_k`, `truncation` | [docs.voyageai.com/reference/reranker-api](https://docs.voyageai.com/reference/reranker-api) |
| Zerank | `https://api.zeroentropy.dev/v1/rerank` | `model`, `query`, `documents` | [docs.zeroentropy.dev](https://docs.zeroentropy.dev) |

Cohere has an official SDK (`cohere-ai`) if you prefer it — pass
`{ signal: AbortSignal.timeout(4000) }` as `requestOptions` to keep timeout
behaviour consistent with the generic wrapper.

## Self-hosted reranking

For high-volume or privacy-sensitive workloads, host a cross-encoder behind a
small HTTP service (FastAPI + `sentence-transformers`):

```python
# reranker_service.py
from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import CrossEncoder

app = FastAPI()
model = CrossEncoder('BAAI/bge-reranker-v2-m3')  # load once at startup

class Req(BaseModel):
    query: str
    documents: list[str]
    top_n: int = 10

@app.post("/rerank")
async def rerank(req: Req):
    pairs = [[req.query, d] for d in req.documents]
    scores = model.predict(pairs)
    ranked = sorted(enumerate(scores), key=lambda x: x[1], reverse=True)
    return [{"index": i, "score": float(s)} for i, s in ranked[:req.top_n]]
```

Run with `uvicorn reranker_service:app --host 0.0.0.0 --port 8000`. Call from
the application using the same generic wrapper above (URL = your service URL,
no `Authorization` header needed).

## Two-stage retrieval pattern

```
Stage 1: BM25 / Hybrid search (fast)
  ├─ Get 50-100 candidates via inverted index or HNSW
  └─ O(log n) per query

Stage 2: Cross-encoder rerank (precise)
  ├─ Score each candidate with full query attention
  └─ O(n) for n candidates
```

Cross-encoders partially rediscover a semantic variant of BM25 (attention
heads ≈ soft TF, embedding matrix ≈ semantic IDF), which is why BM25 +
cross-encoder works so well together.

## When NOT to re-rank

- Real-time autocomplete (latency critical)
- Very large candidate sets (> 100 docs → too slow)
- Simple exact-match queries (BM25 is already optimal)

## Choosing a reranker

```
Priority?
├─ Best quality → Cohere v4.0-pro or Zerank 2
├─ Low latency → Voyage Rerank 2.5-lite or Cohere v4.0-fast
├─ Self-hosted → bge-reranker-v2-m3 or Qwen3-Reranker-4B
└─ Free tier → Cohere (1000/month) or self-hosted
```

## References

- [Cohere Rerank docs](https://docs.cohere.com/docs/rerank)
- [Voyage Rerank API](https://docs.voyageai.com/reference/reranker-api)
- [BAAI bge-reranker](https://huggingface.co/BAAI/bge-reranker-v2-m3)
- [Qwen3 Reranker](https://huggingface.co/Qwen/Qwen3-Reranker-4B)
- [Sentence Transformers Cross-Encoders](https://www.sbert.net/docs/cross_encoder/usage/usage.html)
