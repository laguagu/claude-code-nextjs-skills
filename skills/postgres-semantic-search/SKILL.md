---
name: postgres-semantic-search
description: |
  PostgreSQL-based semantic and hybrid search with pgvector extension.
  Use when implementing vector search, semantic search, or hybrid search
  in PostgreSQL. Covers pgvector setup, indexing (HNSW, IVFFlat), hybrid
  search (FTS + BM25 + RRF), and performance optimization. Supports
  vector(1536) and halfvec(3072) types for different embedding models.

  Triggers: pgvector, vector search, semantic search, hybrid search,
  embedding search, PostgreSQL RAG, BM25, RRF, HNSW index, similarity search
---

# PostgreSQL Semantic Search

## Quick Start

### 1. Setup

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(1536)  -- text-embedding-3-small
    -- Or: embedding halfvec(3072)  -- text-embedding-3-large (50% memory)
);
```

### 2. Basic Semantic Search

```sql
SELECT id, content, 1 - (embedding <=> query_vec) AS similarity
FROM documents
ORDER BY embedding <=> query_vec
LIMIT 10;
```

### 3. Add Index (> 10k documents)

```sql
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
```

## Cheat Sheet

### Distance Operators

```sql
embedding <=> query  -- Cosine distance (1 - similarity)
embedding <-> query  -- L2/Euclidean distance
embedding <#> query  -- Negative inner product
```

### Common Queries

```sql
-- Top 10 similar (cosine)
SELECT * FROM docs ORDER BY embedding <=> $1 LIMIT 10;

-- With similarity score
SELECT *, 1 - (embedding <=> $1) AS similarity FROM docs ORDER BY 2 DESC LIMIT 10;

-- With threshold
SELECT * FROM docs WHERE embedding <=> $1 < 0.3 ORDER BY 1 LIMIT 10;

-- Preload index (run on startup)
SELECT 1 FROM docs ORDER BY embedding <=> $1 LIMIT 1;
```

### Index Quick Reference

```sql
-- HNSW (recommended)
CREATE INDEX ON docs USING hnsw (embedding vector_cosine_ops);

-- With tuning
CREATE INDEX ON docs USING hnsw (embedding vector_cosine_ops)
WITH (m = 24, ef_construction = 200);

-- Query-time recall
SET hnsw.ef_search = 100;

-- Iterative scan for filtered queries (pgvector 0.8+)
SET hnsw.iterative_scan = relaxed_order;
SET ivfflat.iterative_scan = on;
```

## Decision Trees

### Choose Search Method

```
Query type?
├─ Conceptual/meaning-based → Pure vector search
├─ Exact terms/names → Pure keyword search
└─ Mixed/unknown → Hybrid search
    ├─ Simple setup → FTS + RRF (no extra extensions)
    └─ Best ranking → BM25 + RRF (requires pg_search)
```

### Choose Index Type

```
Document count?
├─ < 10,000 → No index needed
├─ 10k - 1M → HNSW (best recall)
└─ > 1M → IVFFlat (less memory) or HNSW
```

### Choose Vector Type

```
Embedding model?
├─ text-embedding-3-small (1536) → vector(1536)
├─ text-embedding-3-large (3072) → halfvec(3072) (50% memory savings)
└─ Other models → vector(dimensions)
```

## Operators

| Operator | Distance | Use Case |
|----------|----------|----------|
| `<=>` | Cosine | Text embeddings (default) |
| `<->` | L2/Euclidean | Image embeddings |
| `<#>` | Inner product | Normalized vectors |

## SQL Functions

### Semantic Search
- `match_documents(query_vec, threshold, limit)` - Basic search
- `match_documents_filtered(query_vec, metadata_filter, threshold, limit)` - With JSONB filter
- `match_chunks(query_vec, threshold, limit)` - Search document chunks

### Hybrid Search (FTS)
- `hybrid_search_fts(query_vec, query_text, limit, rrf_k, language)` - FTS + RRF
- `hybrid_search_weighted(query_vec, query_text, limit, sem_weight, kw_weight)` - Linear combination
- `hybrid_search_fallback(query_vec, query_text, limit)` - Graceful degradation

### Hybrid Search (BM25)
- `hybrid_search_bm25(query_vec, query_text, limit, rrf_k)` - BM25 + RRF
- `hybrid_search_bm25_highlighted(...)` - With snippet highlighting
- `hybrid_search_chunks_bm25(...)` - For RAG with chunks

## Re-ranking (Optional)

Two-stage retrieval improves precision: fast recall → precise rerank.

### When to Use

- Results need higher precision
- Using < 50 candidates after initial search
- Have budget for API calls (Cohere) or compute (local models)

### Options

| Method | Latency | Quality | Cost |
|--------|---------|---------|------|
| Cohere Rerank | ~200ms | Excellent | $0.001/query |
| Cross-encoder | ~500ms | Excellent | Compute |
| LLM rerank | ~1-2s | Good | API cost |

### TypeScript Example (Cohere)

```typescript
import { CohereClient } from 'cohere-ai';

const cohere = new CohereClient({ token: process.env.COHERE_API_KEY });

async function rerankResults(query: string, documents: string[]) {
  const response = await cohere.rerank({
    model: 'rerank-v3.5',
    query,
    documents,
    topN: 10,
  });
  return response.results;
}
```

- [reranking.md](references/reranking.md) - Detailed guide

## References

- [vector-types.md](references/vector-types.md) - vector vs halfvec, dimensions, storage
- [indexing.md](references/indexing.md) - HNSW, IVFFlat, GIN parameters
- [hybrid-search.md](references/hybrid-search.md) - FTS, BM25, RRF algorithms
- [performance.md](references/performance.md) - Cold-start, memory, query optimization

## Scripts

- [setup.sql](scripts/setup.sql) - Extension and table setup
- [semantic_search.sql](scripts/semantic_search.sql) - Semantic search functions
- [hybrid_search_fts.sql](scripts/hybrid_search_fts.sql) - FTS hybrid functions
- [hybrid_search_bm25.sql](scripts/hybrid_search_bm25.sql) - BM25 hybrid functions
- [indexes.sql](scripts/indexes.sql) - Index creation scripts

## Common Patterns

### TypeScript Integration (Supabase)

```typescript
// Semantic search
const { data } = await supabase.rpc('match_documents', {
  query_embedding: embedding,
  match_threshold: 0.7,
  match_count: 10
});

// Hybrid search
const { data } = await supabase.rpc('hybrid_search_fts', {
  query_embedding: embedding,
  query_text: userQuery,
  match_count: 10,
  rrf_k: 60,
  fts_language: 'simple'
});
```

### Drizzle ORM

```typescript
import { sql } from 'drizzle-orm';

const results = await db.execute(sql`
  SELECT * FROM match_documents(
    ${embedding}::vector(1536),
    0.7,
    10
  )
`);
```

## Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| Index not used | < 10k rows or planner choice | Normal for small tables, check with EXPLAIN |
| Slow first query (30-60s) | HNSW cold-start | `SELECT pg_prewarm('idx_name')` or preload query |
| Poor recall | Low ef_search | `SET hnsw.ef_search = 100` or higher |
| FTS returns nothing | Wrong language config | Use `'simple'` for mixed/unknown languages |
| Memory error on index build | maintenance_work_mem too low | Increase to 2GB+ |
| Cosine similarity > 1 | Vectors not normalized | Normalize before insert or use L2 |
| Slow inserts | Index overhead | Batch inserts, consider IVFFlat |

## Version Info (January 2026)

- **pgvector 0.8.x**: Iterative scans, PostgreSQL 18 support, halfvec up to 4000 dims
- **pg_search 0.21.0**: MVCC visibility, parallel aggregation, varchar[] indexing

## External Documentation

- [pgvector GitHub](https://github.com/pgvector/pgvector) - Official extension, latest features
- [OpenAI Embeddings Guide](https://platform.openai.com/docs/guides/embeddings) - Embedding models and best practices
- [Supabase Vector Guide](https://supabase.com/docs/guides/ai/vector-columns) - Supabase-specific integration
- [ParadeDB pg_search](https://docs.paradedb.com/search/quickstart) - BM25 extension documentation
- [PostgreSQL FTS](https://www.postgresql.org/docs/current/textsearch.html) - Built-in full-text search
