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

```
Embedding model?
├─ OpenAI text-embedding-3-small (1536)      → vector(1536)
├─ OpenAI text-embedding-3-large (3072)      → halfvec(3072) (50% memory savings)
├─ Voyage voyage-4 / voyage-4-large (1024)   → vector(1024) or halfvec(1024)
├─ Voyage voyage-multilingual-2 (1024)       → vector(1024) (best Finnish/multilingual)
├─ Gemini embedding-001 (3072 or 1024 Matryoshka) → halfvec(…)
├─ Cohere embed-v4 (1024)                    → vector(1024)
├─ Qwen3-Embedding-8B (up to 4096)           → vector(…) (best open MTEB multilingual)
├─ BGE-M3 / Jina v3 (1024)                   → vector(1024) (self-hosted, Finnish OK)
└─ Other models → vector(dimensions)
```

**Finnish / Nordic retrieval**: prefer Voyage `voyage-multilingual-2` or self-hosted `BGE-M3` / `Qwen3-Embedding`. OpenAI `text-embedding-3-large` is a solid fallback but weaker cross-lingual than Voyage. Avoid `text-embedding-3-small` for Finnish — compound words suffer.

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

Two-stage retrieval improves precision: fast recall → precise rerank.

### When to Use

- Results need higher precision
- Using < 50 candidates after initial search
- Have budget for API calls (Cohere) or compute (local models)

### Options

| Method | Latency (30 docs) | Quality | Notes |
|--------|-------------------|---------|-------|
| Cohere Rerank v4.0-fast | ~150ms | Excellent | Free tier 1000/month |
| Cohere Rerank v4.0-pro | ~300ms | Best | 32K context, self-learning |
| Voyage Rerank 2.5-lite | ~600ms | Very Good | Default for most apps; ~2× cheaper than full |
| Voyage Rerank 2.5 | ~1200ms | Excellent | When latency budget allows full quality |
| Zerank 2 (Zeroentropy) | ~100ms | Best | Fastest paid option |
| Jina Reranker v2 | ~150ms | Very Good | Good multilingual |
| BGE-reranker-v2-m3 (self-host) | ~300ms | Very Good | Open weights, Finnish OK |
| Cross-encoder (local, e.g. ms-marco-MiniLM) | ~500ms | Good | CPU-friendly |

Check provider docs for current pricing — models and prices change monthly.

> **Voyage payment gotcha**: Without a payment method on file, Voyage limits API
> to 3 RPM (effectively unusable). Add a card at
> [dash.voyageai.com/billing](https://dash.voyageai.com/billing) to unlock the
> 200M tokens/month free tier. No charge until you exceed the quota.

### Production-pattern: graceful fallback

Reranking should be an *enhancement*, not a *requirement*. Wrap reranker calls
to return `null` on any failure (missing key, HTTP error, AbortController
timeout) — the caller falls back to the original retrieval order. Pattern is
provider-agnostic. Full example in
[reranking.md](references/reranking.md#production-patterns-apply-to-any-reranker).

### TypeScript Example (Cohere)

```typescript
import { CohereClient } from 'cohere-ai';

const cohere = new CohereClient({ token: process.env.COHERE_API_KEY });

async function rerankResults(query: string, documents: string[]) {
  // ALWAYS use a timeout in production — a slow reranker shouldn't hang the request
  const response = await cohere.rerank(
    {
      model: 'rerank-v4.0-fast',  // or 'rerank-v4.0-pro' for best quality
      query,
      documents,
      topN: 10,
    },
    { signal: AbortSignal.timeout(4000) },
  );
  return response.results;
}
```

For a production-ready wrapper that returns `null` on failure (so search
continues with original results), see
[reranking.md → Production patterns](references/reranking.md#production-patterns-apply-to-any-reranker).

## Multilingual & Finnish search tips

When the corpus is Finnish (or contains Finnish):

- **FTS language config**: `to_tsvector('finnish', text)` in stock PostgreSQL applies the built-in snowball stemmer (handles `opiskelija → opiskelij`, `lääkäreiden → lääkäri`). For mixed-language corpora use `'simple'` and supply morphology via a Voikko-backed function or via ParadeDB `pg_search`'s `stemmer: "Finnish"` tokenizer.
- **Prefix tsquery** (handles Finnish inflection without a real morphology engine):

  ```sql
  CREATE OR REPLACE FUNCTION prefix_tsquery(p text)
  RETURNS tsquery LANGUAGE sql IMMUTABLE AS $$
    SELECT to_tsquery('simple',
      string_agg(word || ':*', ' & '))
    FROM regexp_split_to_table(lower(regexp_replace(p, '[^\w\säöåÄÖÅ-]', ' ', 'g')), '\s+') AS word
    WHERE length(word) >= 2
  $$;
  ```
  Then `search_tsv @@ prefix_tsquery('sairaanhoitaja tampere')` matches inflected forms.

- **Compound-word fallback**: `pg_trgm` similarity on `nimi_fi` catches compound-word misses (`"ammattikorkea"` → `"ammattikorkeakoulu"`). Pair with a GIN trigram index.
- **BM25 stemmer**: in ParadeDB pg_search, tokenize with `{ "type": "default", "stemmer": "Finnish" }` — a `raw` tokenizer only matches full fields.
- **Embeddings**: `voyage-multilingual-2` or `BGE-M3` for best Finnish semantic quality. `text-embedding-3-large` is acceptable but loses some compound-word precision.
- **Query translation (optional)**: if users type English against Finnish content, detect language heuristically (ä/ö presence + suffix/stem count), and translate with a small chat model before hitting FTS.
- **Adaptive weighting**: short Finnish queries (1–2 words) benefit from higher keyword weight; long intent queries (6+ words) benefit from higher semantic/context weight. See `references/hybrid-search.md` for RRF details.

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
