---
name: postgres-semantic-search
description: |
  PostgreSQL-based semantic and hybrid search with pgvector and ParadeDB.
  Use when implementing vector search, semantic search, hybrid search,
  or full-text search in PostgreSQL. Covers pgvector indexing, hybrid
  FTS/BM25 + RRF, ParadeDB, reranking, halfvec, multilingual search,
  query translation, and domain evals.

  Triggers: pgvector, vector search, semantic search, hybrid search,
  embedding search, PostgreSQL RAG, BM25, RRF, HNSW index, similarity
  search, ParadeDB, pg_search, reranking, Cohere rerank, Voyage rerank,
  graceful fallback, iterative_scan, filtered HNSW, websearch_to_tsquery,
  unaccent, multilingual FTS, pg_trgm, trigram, fuzzy search, LIKE, ILIKE,
  autocomplete, typo tolerance, fuzzystrmatch, evaluation, benchmarking,
  Hit@K, MRR, halfvec cast, cross-lingual retrieval, non-English corpus,
  per-language indexing, query translation, RRF fusion across languages
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
    embedding vector(1536)  -- 1536-dim embedding
    -- Or: embedding halfvec(3072)  -- 3072-dim embedding (halfvec = 50% memory)
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
  paradedb/paradedb:latest  # `latest` is convenient for quick-start; pin to e.g. paradedb/paradedb:pg17 for reproducible builds
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

Common embedding dimensions are 1536 and 3072, but sizes vary by provider
and model — check the provider's docs for the embedding you're using.

For **multilingual** / non-English content, prefer multilingual-tuned embedding
models (look for "multilingual" in the model name). Models tuned only on
English may handle compound words and inflection poorly.

**Storage vs. index trick** for 2000 < N ≤ 4000: keep the column as `vector(N)`
(full float4, useful for future re-embedding or re-ranking experiments) and
*only* cast at index creation and query time. This preserves precision on disk
while staying within HNSW's dimension limit.

```sql
CREATE INDEX ON docs USING hnsw ((embedding::halfvec(3072)) halfvec_cosine_ops);
-- Query must cast identically so the planner picks the index:
SELECT * FROM docs ORDER BY embedding::halfvec(3072) <=> $1 LIMIT 10;
```

If storage is tight or you never plan to re-embed, use `halfvec(N)` as the
column type directly.

## Measure before adopting

Every optimization in this skill (hybrid fusion, reranking, query expansion,
embedding-model swaps) *can* regress on a specific corpus. Vendor and paper
benchmarks are usually English, general-domain. Real counter-examples observed
in production:

- Query expansion (HyDE) regressing Hit@5 by tens of points on a domain corpus.
- A widely recommended reranker regressing Hit@5 double-digits on multilingual text.

**Rule**: build a domain eval set ([evaluation.md](references/evaluation.md)),
then A/B each change. Adopt with ≥ +3 pp Hit@5 and p95 latency within budget;
reject otherwise.

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
- **Multilingual embeddings**: prefer models explicitly trained on your target language(s). English-only embeddings often miss inflected forms and compound words. The gap can be large — multilingual-tuned embeddings have been observed to beat general-purpose English-tuned ones by 10+pp Hit@5 on non-English retrieval. Benchmark your specific language + domain before committing.
- **Cross-language RRF fusion for monolingual corpora**: when the corpus is
  one language and queries arrive in many, run two hybrid passes per
  off-language query (original-language embedding + translated-language
  embedding, same FTS text) and RRF-merge. Recovers domain terms that
  cross-lingual embeddings collapse. See [hybrid-search.md →
  Cross-language RRF fusion pattern](references/hybrid-search.md#cross-language-rrf-fusion-pattern).

- **Per-language indexing for multilingual content**: when translated
  content exists, add `language_code` to the chunk table (default to the
  original language so existing rows backfill), include it in the
  uniqueness constraint, and scope ingest writes/deletes to one language.
  Search stays language-agnostic; native-language queries hit native
  embeddings directly.

  ```sql
  ALTER TABLE chunks ADD COLUMN language_code TEXT NOT NULL DEFAULT 'en';
  ALTER TABLE chunks DROP CONSTRAINT chunks_doc_chunk_unique;
  ALTER TABLE chunks ADD CONSTRAINT chunks_doc_chunk_lang_unique
    UNIQUE (doc_id, chunk_index, language_code);
  CREATE INDEX chunks_doc_lang_idx ON chunks (doc_id, language_code);
  ```

## References

- [fuzzy-search.md](references/fuzzy-search.md) - pg_trgm, fuzzy matching, LIKE/ILIKE, autocomplete, advanced FTS
- [paradedb.md](references/paradedb.md) - ParadeDB full-text search (Elasticsearch alternative)
- [vector-types.md](references/vector-types.md) - vector vs halfvec, dimensions, storage
- [indexing.md](references/indexing.md) - HNSW, IVFFlat, GIN parameters
- [hybrid-search.md](references/hybrid-search.md) - FTS, BM25, RRF algorithms
- [performance.md](references/performance.md) - Cold-start, memory, HNSW vs IVFFlat
- [evaluation.md](references/evaluation.md) - Eval-set construction, Hit@K / MRR, adoption thresholds, reranker/expansion benchmarking
- [reranking.md](references/reranking.md) - Two-stage retrieval, graceful fallback, when rerankers regress

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
- [OpenAI Embeddings](https://platform.openai.com/docs/guides/embeddings) - model list + dimensions
- [Voyage Embeddings](https://docs.voyageai.com/docs/embeddings) - includes multilingual model
- [Cohere Embed](https://docs.cohere.com/docs/embeddings) - model list
- [HuggingFace Hub](https://huggingface.co/models?pipeline_tag=sentence-similarity) - open-weight embeddings

### Reranker providers
- [Cohere Rerank](https://docs.cohere.com/docs/rerank)
- [Voyage Rerank](https://docs.voyageai.com/reference/reranker-api)
- [Zerank](https://docs.zeroentropy.dev)
- [Sentence Transformers](https://www.sbert.net/docs/cross_encoder/usage/usage.html) - self-hosted cross-encoders

### Hosting / extensions
- [Supabase Vector Guide](https://supabase.com/docs/guides/ai/vector-columns) - Supabase-specific integration
- [ParadeDB pg_search](https://docs.paradedb.com/documentation/getting-started/quickstart) - BM25 extension documentation
- [ParadeDB AI Docs](https://docs.paradedb.com/llms-full.txt) - Fetch for latest ParadeDB API (always current)
