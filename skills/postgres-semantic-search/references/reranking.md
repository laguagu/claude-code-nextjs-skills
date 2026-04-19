# Re-ranking Guide

Re-ranking is a two-stage retrieval pattern:

1. **Stage 1:** Fast retrieval (vector/hybrid search) - get 50-100 candidates
2. **Stage 2:** Precise re-ranking - score candidates with better model

## Why Re-rank?

| Retrieval | Re-ranker |
|-----------|-----------|
| Bi-encoder (fast) | Cross-encoder (slow, accurate) |
| Single embedding per doc | Compares query+doc together |
| O(1) per doc | O(n) for n candidates |

## Reranker Options (2026)

### API Services

| Service | Latency (30 docs) | Quality | Languages | Notes |
|---------|-------------------|---------|-----------|-------|
| Cohere Rerank v4.0-pro | ~300ms | Best | 100+ | 32K context, self-learning |
| Cohere Rerank v4.0-fast | ~150ms | Excellent | 100+ | Low latency variant |
| Zerank 2 | ~100ms | Best | 100+ | Wins most benchmarks |
| Voyage Rerank 2.5 | ~1200ms | Excellent | 100+ | Higher latency, full-quality |
| Voyage Rerank 2.5-lite | ~600ms | Very Good | 100+ | ~2× cheaper tokens, near-equivalent quality on small/non-English corpora |

> Latency numbers are wall-clock observations from a real workload (30 candidates,
> ~150 tokens each, EU → provider). Treat as ballpark; benchmark in your own region.

### Open-Source Models

| Model | Size | Speed | Quality | Notes |
|-------|------|-------|---------|-------|
| Qwen3-Reranker-8B | 8B | Slow | Excellent | Best open-source |
| Qwen3-Reranker-4B | 4B | Medium | Very Good | Balanced |
| Qwen3-Reranker-0.6B | 0.6B | Fast | Good | Latency-constrained |
| bge-reranker-v2-m3 | 560M | Fast | Very Good | Multilingual, BAAI |
| Jina Reranker v2 | 278M | Fast | Good | Lightweight |

### Legacy Models (still functional)

| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| ms-marco-MiniLM-L-6-v2 | 80MB | Fast | Acceptable |
| ms-marco-electra-base | 400MB | Slow | Good |

## Production patterns (apply to ANY reranker)

Re-ranking is an *enhancement*, not a *requirement*. A failed rerank call should
not break the search — fall back to the original retrieval order.

### Graceful fallback

Wrap reranker calls so they return `null` on any failure (missing key, HTTP
error, timeout). The caller decides what to do (use original order):

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

// Usage
const reranked = await rerank(query, candidates, 10);
const final = reranked
  ? reranked.map(r => candidates.find(c => c.id === r.id)!).filter(Boolean)
  : candidates.slice(0, 10);  // Fallback: original RRF order
```

### Why this matters

- **API outage**: provider is down → search still works
- **Rate limit (429)**: free-tier or burst exceeded → search still works
- **Slow response (> 4 s)**: AbortController triggers → search still works
- **Missing API key in dev**: return null silently → search still works

This pattern is **provider-agnostic** — adapt for Cohere, Voyage, Zerank, or
self-hosted endpoints by swapping URL + body shape.

## Cohere Rerank API

Best option for production - fast, accurate, simple.

### Setup

```bash
bun add cohere-ai
```

### Usage (with timeout — see Production patterns above)

```typescript
import { CohereClient } from 'cohere-ai';

const cohere = new CohereClient({ token: process.env.COHERE_API_KEY });

interface SearchResult {
  id: number;
  content: string;
  score: number;
}

async function searchWithRerank(
  query: string,
  embedding: number[],
  topK: number = 10
): Promise<SearchResult[]> {
  // Stage 1: Get candidates (3x final count)
  const candidates = await db.execute(sql`
    SELECT id, content, 1 - (embedding <=> ${embedding}::vector) as score
    FROM documents
    ORDER BY embedding <=> ${embedding}::vector
    LIMIT ${topK * 3}
  `);

  // Stage 2: Re-rank with Cohere v4.0
  // NOTE: cohere-ai SDK accepts AbortSignal via requestOptions parameter
  const reranked = await cohere.rerank({
    model: 'rerank-v4.0-fast',  // or 'rerank-v4.0-pro' for best quality
    query,
    documents: candidates.map(c => c.content),
    topN: topK,
  }, { signal: AbortSignal.timeout(4000) });

  // Map back to original results
  return reranked.results.map(r => ({
    ...candidates[r.index],
    score: r.relevanceScore,
  }));
}
```

### Cohere v4.0 Features

- **32K token context window** (4x increase from v3.5)
- **Semi-structured data support** (JSON, tables)
- **Self-learning capability** for enterprise deployments
- **100+ language support** with state-of-the-art retrieval

### Pricing (always verify at [cohere.com/pricing](https://cohere.com/pricing))

- **rerank-v4.0-pro**: ~$0.002 per search (up to 100 docs)
- **rerank-v4.0-fast**: ~$0.001 per search (up to 100 docs)
- **Free tier**: 1000 searches/month

## Voyage Rerank API

Cheap and fast alternative — useful when Cohere's free tier is exhausted or you
need lower latency on small batches.

### Pricing model gotcha

Voyage requires a **payment method on file** to unlock production rate limits,
even if you stay under the free quota:

| State | Limit |
|-------|-------|
| Without payment method | 3 RPM, 10K TPM (effectively unusable in production) |
| With payment method | 200M tokens/month free, then $0.05/M |

Without a card, you'll see HTTP 429 in production immediately. Add the card at
[dash.voyageai.com/billing](https://dash.voyageai.com/billing) — no charge until
you exceed the free tier.

### Choosing a model

| Model | Use when |
|-------|----------|
| `rerank-2.5` | Maximum quality matters, latency budget allows ~1s per call |
| `rerank-2.5-lite` | Better default for most apps — ~2× faster, ~2× cheaper, near-identical quality on small (< 50 candidates) and non-English corpora |

### Usage (no SDK — plain fetch + AbortController)

```typescript
const VOYAGE_URL = 'https://api.voyageai.com/v1/rerank';

interface RerankResult { id: number; score: number }

async function voyageRerank(
  query: string,
  candidates: { id: number; text: string }[],
  topK = 10,
): Promise<RerankResult[] | null> {
  const apiKey = process.env.VOYAGE_API_KEY;
  if (!apiKey || candidates.length === 0) return null;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 4_000);

  try {
    const resp = await fetch(VOYAGE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        query,
        documents: candidates.map(c => c.text.slice(0, 4000)), // Voyage doc limit
        model: process.env.VOYAGE_RERANK_MODEL ?? 'rerank-2.5-lite',
        top_k: Math.min(topK, candidates.length),
        truncation: true,
      }),
      signal: controller.signal,
    });

    if (!resp.ok) {
      console.warn(`[rerank] Voyage HTTP ${resp.status}`);
      return null;
    }

    const json = (await resp.json()) as {
      data: Array<{ index: number; relevance_score: number }>;
    };
    return json.data.map(r => ({
      id: candidates[r.index].id,
      score: r.relevance_score,
    }));
  } catch (e) {
    console.warn(`[rerank] Voyage error: ${(e as Error).message}`);
    return null;
  } finally {
    clearTimeout(timer);
  }
}
```

### Voyage docs

- [Voyage Rerank API reference](https://docs.voyageai.com/reference/reranker-api)
- [Voyage pricing](https://www.voyageai.com/pricing)

## Self-Hosted Reranking (FastAPI)

For high-volume or privacy-sensitive workloads.

### Python Service

```python
# reranker_service.py
from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import CrossEncoder

app = FastAPI()

# Load model once at startup
model = CrossEncoder('BAAI/bge-reranker-v2-m3')

class RerankRequest(BaseModel):
    query: str
    documents: list[str]
    top_n: int = 10

class RerankResult(BaseModel):
    index: int
    score: float

@app.post("/rerank")
async def rerank(request: RerankRequest) -> list[RerankResult]:
    pairs = [[request.query, doc] for doc in request.documents]
    scores = model.predict(pairs)

    # Sort by score descending
    ranked = sorted(enumerate(scores), key=lambda x: x[1], reverse=True)

    return [
        RerankResult(index=idx, score=float(score))
        for idx, score in ranked[:request.top_n]
    ]

@app.get("/health")
async def health():
    return {"status": "ok"}
```

### Run the Service

```bash
pip install fastapi uvicorn sentence-transformers
uvicorn reranker_service:app --host 0.0.0.0 --port 8000
```

### TypeScript Client

```typescript
interface RerankResult {
  index: number;
  score: number;
}

async function rerankWithLocalService(
  query: string,
  documents: string[],
  topN: number = 10
): Promise<RerankResult[]> {
  const response = await fetch('http://localhost:8000/rerank', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, documents, top_n: topN }),
  });
  return response.json();
}

// Usage with search results
async function searchWithLocalRerank(
  query: string,
  embedding: number[],
  topK: number = 10
) {
  // Stage 1: Get candidates
  const candidates = await db.execute(sql`
    SELECT id, content FROM documents
    ORDER BY embedding <=> ${embedding}::vector
    LIMIT ${topK * 3}
  `);

  // Stage 2: Rerank with local service
  const reranked = await rerankWithLocalService(
    query,
    candidates.map(c => c.content),
    topK
  );

  // Map back to original results
  return reranked.map(r => ({
    ...candidates[r.index],
    score: r.score,
  }));
}
```

## Two-Stage Retrieval Pattern

For best results, use BM25 or hybrid search for initial retrieval before cross-encoder reranking:

```
Stage 1: BM25/Hybrid Search (fast)
├─ Get 50-100 candidates
├─ Uses inverted index or HNSW
└─ O(log n) per query

Stage 2: Cross-Encoder Rerank (precise)
├─ Score each candidate with query
├─ Full cross-attention
└─ O(n) for n candidates
```

### Why This Works

Cross-encoders partially rediscover a semantic variant of BM25:
- Transformer attention heads compute soft term frequency
- Embedding matrix encodes inverse document frequency semantically
- Built-in term saturation and document length normalization

This explains why BM25 + cross-encoder works so well together.

## When NOT to Re-rank

- Real-time autocomplete (latency critical)
- \> 100 candidates (too slow)
- Simple exact-match queries
- Budget constraints without free tier

## Choosing a Reranker

```
Priority?
├─ Best quality → Cohere v4.0-pro or Zerank 2
├─ Low latency → Voyage Rerank 2.5 or Cohere v4.0-fast
├─ Self-hosted → bge-reranker-v2-m3 or Qwen3-Reranker-4B
└─ Budget → Self-hosted or Cohere free tier
```

## References

- [Cohere Rerank v4.0 Docs](https://docs.cohere.com/docs/rerank)
- [Cohere v4.0 Changelog](https://docs.cohere.com/changelog/rerank-v4.0)
- [BAAI bge-reranker](https://huggingface.co/BAAI/bge-reranker-v2-m3)
- [Sentence Transformers Cross-Encoders](https://www.sbert.net/docs/cross_encoder/usage/usage.html)
- [Qwen3 Reranker](https://huggingface.co/Qwen/Qwen3-Reranker-4B)
