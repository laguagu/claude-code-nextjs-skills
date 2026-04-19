---
name: postgres-semantic-search
description: |
  PostgreSQL-based semantic and hybrid search with pgvector and ParadeDB.
  Use when implementing vector search, semantic search, hybrid search,
  or full-text search in PostgreSQL. Covers pgvector setup, indexing
  (HNSW, IVFFlat), hybrid search (FTS + BM25 + RRF), ParadeDB as
  Elasticsearch alternative, and re-ranking with Cohere/cross-encoders.
  Supports vector(1536) and halfvec(3072) types for OpenAI embeddings.

  Triggers: pgvector, vector search, semantic search, hybrid search,
  embedding search, PostgreSQL RAG, BM25, RRF, HNSW index, similarity search,
  ParadeDB, pg_search, reranking, Cohere rerank, Voyage rerank,
  graceful fallback, iterative_scan, filtered HNSW, websearch_to_tsquery,
  unaccent, multilingual FTS, pg_trgm, trigram, fuzzy search, LIKE, ILIKE,
  autocomplete, typo tolerance, fuzzystrmatch
argument-hint: "[question or use case]"
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

### Docker Quick Start

```bash
# pgvector with PostgreSQL 17
docker run -d --name pgvector-db \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  pgvector/pgvector:pg17

# Or PostgreSQL 18 (latest)
docker run -d --name pgvector-db \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  pgvector/pgvector:pg18

# ParadeDB (includes pgvector + pg_search + BM25)
docker run -d --name paradedb \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  paradedb/paradedb:latest
```

Connect: `psql postgresql://postgres:postgres@localhost:5432/postgres`

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
├─ Exact terms/names → Pure keyword search (FTS)
├─ Fuzzy/typo-tolerant → pg_trgm trigram similarity
├─ Autocomplete/prefix → pg_trgm + prefix index
├─ Substring (LIKE/ILIKE) → pg_trgm GIN index
└─ Mixed/unknown → Hybrid search
    ├─ Simple setup → FTS + RRF (no extra extensions)
    ├─ Better ranking → BM25 + RRF (pg_search extension)
    └─ Full-featured → ParadeDB (Elasticsearch alternative)
```

### Choose Index Type

```
Document count?
├─ < 10,000 → No index needed
├─ 10k - 1M → HNSW (best recall)
└─ > 1M → IVFFlat (less memory) or HNSW
```

### Choose Vector Type

Choose by **dimensions**, not by provider — the column type only depends on
embedding size and pgvector's HNSW index limits.

```
Embedding dimensions (N)?
├─ N ≤ 2000  → vector(N)   — HNSW indexable directly
├─ 2000 < N ≤ 4000 → halfvec(N) — vector(N)'s HNSW limit is 2000; halfvec extends to 4000
└─ N > 4000  → vector(N) without HNSW, or quantize via dimensionality reduction
```

Common dimensions for current OpenAI models: `text-embedding-3-small` = 1536,
`text-embedding-3-large` = 3072. Other providers vary — check provider docs.

For **multilingual** / non-English content, prefer multilingual-tuned embedding
models (look for "multilingual" in the model name). Models tuned only on
English may handle compound words and inflection poorly.

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

### Fuzzy Search (pg_trgm)
- `fuzzy_search_trigram(query_text, threshold, limit)` - Trigram similarity search
- `autocomplete_search(prefix, limit)` - Prefix + fuzzy autocomplete
- `hybrid_search_fuzzy_semantic(query_text, query_vec, limit, rrf_k)` - Fuzzy + vector RRF
- `weighted_fts_search(query_text, language, limit)` - FTS with title/content weighting

### Hybrid Search (FTS)
- `hybrid_search_fts(query_vec, query_text, limit, rrf_k, language)` - FTS + RRF
- `hybrid_search_weighted(query_vec, query_text, limit, sem_weight, kw_weight)` - Linear combination
- `hybrid_search_fallback(query_vec, query_text, limit)` - Graceful degradation

### Hybrid Search (BM25)
- `hybrid_search_bm25(query_vec, query_text, limit, rrf_k)` - BM25 + RRF
- `hybrid_search_bm25_highlighted(...)` - With snippet highlighting
- `hybrid_search_chunks_bm25(...)` - For RAG with chunks

## Re-ranking (Optional)

Two-stage retrieval improves precision: fast recall → precise rerank with a
cross-encoder. Use when results need higher precision and you have <50
candidates after initial retrieval.

**Key rule**: rerankers must be wrapped so a failure (missing key, HTTP error,
timeout) returns `null` and the caller falls back to original retrieval order
— never let a reranker outage break search.

For provider comparison, generic `Promise<T | null>` wrapper, and self-hosted
options, see [reranking.md](references/reranking.md).

## Multilingual / non-English content tips

When the corpus is non-English (Finnish, German, French, Spanish, etc.):

- **FTS language config**: pass the matching language to `to_tsvector(language, text)` to apply the built-in snowball stemmer (e.g., `'finnish'` handles `opiskelija → opiskelij`). For mixed-language corpora, use `'simple'` and rely on prefix/trigram fallbacks instead.
- **Combine stemmer + unaccent** for accent-insensitive matching ("café" matches "cafe"). See [hybrid-search.md → Custom FTS configuration](references/hybrid-search.md#custom-fts-configuration-eg-language--unaccent) for the 3-step DDL pattern.
- **Prefix tsquery** for languages with rich inflection (no full morphology engine required):

  ```sql
  CREATE OR REPLACE FUNCTION prefix_tsquery(p text)
  RETURNS tsquery LANGUAGE sql IMMUTABLE AS $$
    SELECT to_tsquery('simple',
      string_agg(word || ':*', ' & '))
    FROM regexp_split_to_table(lower(regexp_replace(p, '[^\w\s-]', ' ', 'g')), '\s+') AS word
    WHERE length(word) >= 2
  $$;
  ```
  Matches `kartta`, `karttaa`, `karttoja` from a single `kartta:*` token.

- **Compound-word fallback**: pair semantic search with `pg_trgm` similarity to catch compound-word misses (e.g., a query for `"ammattikorkea"` should still find `"ammattikorkeakoulu"`).
- **BM25 stemmer in ParadeDB**: tokenize with `{ "type": "default", "stemmer": "<language>" }` — a `raw` tokenizer only matches full fields.
- **Multilingual embeddings**: prefer models explicitly trained on your target language(s). English-only embeddings often miss inflected forms and compound words.

## References

- [fuzzy-search.md](references/fuzzy-search.md) - pg_trgm, fuzzy matching, LIKE/ILIKE, autocomplete, advanced FTS
- [paradedb.md](references/paradedb.md) - ParadeDB full-text search (Elasticsearch alternative)
- [vector-types.md](references/vector-types.md) - vector vs halfvec, dimensions, storage
- [indexing.md](references/indexing.md) - HNSW, IVFFlat, GIN parameters
- [hybrid-search.md](references/hybrid-search.md) - FTS, BM25, RRF algorithms
- [performance.md](references/performance.md) - Cold-start, memory, HNSW vs IVFFlat

## Scripts

- [setup.sql](scripts/setup.sql) - Extension and table setup
- [semantic_search.sql](scripts/semantic_search.sql) - Semantic search functions
- [hybrid_search_fts.sql](scripts/hybrid_search_fts.sql) - FTS hybrid functions
- [hybrid_search_bm25.sql](scripts/hybrid_search_bm25.sql) - BM25 hybrid functions
- [fuzzy_search.sql](scripts/fuzzy_search.sql) - pg_trgm fuzzy search, autocomplete, weighted FTS
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
| Fuzzy search slow | Missing trigram index | `CREATE INDEX USING gin (col gin_trgm_ops)` |
| ILIKE '%x%' slow | No pg_trgm GIN index | Enable pg_trgm + create GIN trigram index |
| `%` operator error | pg_trgm not installed | `CREATE EXTENSION IF NOT EXISTS pg_trgm` |

## Compatibility

- **pgvector**: 0.8+ recommended (iterative scans, halfvec). Check [pgvector releases](https://github.com/pgvector/pgvector/releases).
- **pg_search**: Check [ParadeDB releases](https://github.com/paradedb/paradedb/releases) for latest.
- **PostgreSQL**: 17+ recommended. pgvector supports 13-18.

## Related Skills

| Need | Skill |
|------|-------|
| General Postgres performance, indexes, RLS, connection pooling | `/supabase-postgres-best-practices` |
| Chatbot orchestration, session DB, tool calls, HITL, feedback | `/nextjs-chatbot` |
| AI SDK v6 usage for embeddings and retrieval | `/ai-sdk-6` |

For ParadeDB-specific questions, always apply the Documentation Fetch Policy in [references/paradedb.md](references/paradedb.md) — live docs at `https://docs.paradedb.com/llms-full.txt` are the authoritative source.

## External Documentation

### Core
- [pgvector GitHub](https://github.com/pgvector/pgvector) - Official extension, latest features
- [PostgreSQL FTS](https://www.postgresql.org/docs/current/textsearch.html) - Built-in full-text search

### Embedding providers
- [OpenAI Embeddings Guide](https://platform.openai.com/docs/guides/embeddings) - Embedding models and best practices
- [Voyage Embeddings](https://docs.voyageai.com/docs/embeddings) - Voyage embeddings + multilingual model
- [Cohere Embed](https://docs.cohere.com/docs/embeddings) - Cohere embed-v4

### Reranker providers
- [Cohere Rerank API](https://docs.cohere.com/docs/rerank) - API + pricing
- [Voyage Rerank API](https://docs.voyageai.com/reference/reranker-api) - API reference
- [Voyage pricing & billing](https://www.voyageai.com/pricing) - 200M tokens/month free **after** adding payment method

### Hosting / extensions
- [Supabase Vector Guide](https://supabase.com/docs/guides/ai/vector-columns) - Supabase-specific integration
- [ParadeDB pg_search](https://docs.paradedb.com/documentation/getting-started/quickstart) - BM25 extension documentation
- [ParadeDB AI Docs](https://docs.paradedb.com/llms-full.txt) - Fetch for latest ParadeDB API (always current)
