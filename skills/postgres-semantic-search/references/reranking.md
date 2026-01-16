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

## Cohere Rerank API

Best option for production - fast, accurate, simple.

### Setup

```bash
npm install cohere-ai
```

### Usage

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

  // Stage 2: Re-rank with Cohere
  const reranked = await cohere.rerank({
    model: 'rerank-v3.5',
    query,
    documents: candidates.map(c => c.content),
    topN: topK,
  });

  // Map back to original results
  return reranked.results.map(r => ({
    ...candidates[r.index],
    score: r.relevanceScore,
  }));
}
```

### Pricing (January 2026)

- **rerank-v3.5**: $0.001 per search (up to 100 docs)
- **Free tier**: 1000 searches/month

## Local Cross-Encoder (Optional)

For self-hosted or high-volume scenarios.

### With sentence-transformers (Python)

```python
from sentence_transformers import CrossEncoder

model = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')

def rerank(query: str, documents: list[str]) -> list[tuple[int, float]]:
    pairs = [[query, doc] for doc in documents]
    scores = model.predict(pairs)
    ranked = sorted(enumerate(scores), key=lambda x: x[1], reverse=True)
    return ranked
```

### Models

| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| ms-marco-MiniLM-L-6-v2 | 80MB | Fast | Good |
| ms-marco-TinyBERT-L-2-v2 | 50MB | Fastest | OK |
| cross-encoder/ms-marco-electra-base | 400MB | Slow | Best |

## When NOT to Re-rank

- Real-time autocomplete (latency critical)
- \> 100 candidates (too slow)
- Simple exact-match queries
- Budget constraints without free tier

## References

- [Cohere Rerank Docs](https://docs.cohere.com/docs/rerank)
- [Sentence Transformers Cross-Encoders](https://www.sbert.net/docs/cross_encoder/usage/usage.html)
- [Two-Stage Retrieval Paper](https://arxiv.org/abs/2010.11934)
