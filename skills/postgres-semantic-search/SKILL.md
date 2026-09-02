---
name: postgres-semantic-search
description: |
  PostgreSQL-based semantic and hybrid search with pgvector and ParadeDB.
  Use when implementing vector search, semantic search, hybrid search,
  or full-text search in PostgreSQL. Covers pgvector indexing, hybrid
  FTS/BM25 + RRF, ParadeDB, reranking, halfvec, multilingual search,
  query translation, and domain evals.

  Triggers: pgvector, vector search, semantic search, hybrid search,
  embedding search, PostgreSQL RAG, BM25, RRF, HNSW, IVFFlat, ParadeDB,
  pg_search, reranking, iterative_scan, filtered HNSW, halfvec,
  websearch_to_tsquery, unaccent, multilingual FTS, pg_trgm, trigram,
  fuzzy search, ILIKE, autocomplete, typo tolerance, fuzzystrmatch,
  Hit@K, MRR, retrieval evals, cross-lingual retrieval, non-English
  corpus, per-language indexing, query translation

  For general Postgres schema, index, RLS or query tuning unrelated to
  retrieval, use supabase-postgres-best-practices instead.
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

# Or PostgreSQL 18
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

### Common Queries

```sql
-- Top 10 similar (cosine)
SELECT * FROM docs ORDER BY embedding <=> $1 LIMIT 10;

-- With similarity score
SELECT *, 1 - (embedding <=> $1) AS similarity FROM docs ORDER BY embedding <=> $1 LIMIT 10;

-- With a distance threshold — put the filter OUTSIDE a materialized CTE.
-- Filtering inline (WHERE (embedding <=> $1) < 0.3 ORDER BY ... LIMIT 10) makes
-- the executor apply the filter before the index returns LIMIT rows, so you get
-- fewer results than expected. pgvector documents this CTE form as the fix.
WITH nearest AS MATERIALIZED (
  SELECT id, content, embedding <=> $1 AS distance FROM docs
  ORDER BY distance LIMIT 10
) SELECT * FROM nearest WHERE distance < 0.3 ORDER BY distance;

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

-- Query-time recall. Set this: pgvector's default of 40 costs recall silently
-- (measured ~1.1 pp at 54k vectors for no latency saving; on a 22k-vector
-- corpus recall@20 went 96.2% -> 99.2% for +0.7 ms median). See indexing.md.
-- Query-time settings are connection-local. Use SET LOCAL inside a transaction
-- when a transaction pooler can hand each request a different connection.
SET hnsw.ef_search = 100;

-- Iterative scan for filtered queries (pgvector 0.8+; OFF by default)
SET hnsw.iterative_scan = relaxed_order;    -- or strict_order
SET ivfflat.iterative_scan = relaxed_order; -- IVFFlat has no strict_order
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

**Baseline hybrid against vector-only before shipping it.** Hybrid is the right
default for mixed queries, not an automatic win: on one measured corpus pure
vector beat a well-weighted hybrid on both recall and MRR and was 9× faster,
while a badly weighted one lost 10 pp. The keyword arm still earns its keep for
exact identifiers, which a needle-in-haystack eval set cannot see — so keep it,
and judge it on queries that need it. Numbers in
[hybrid-search.md](references/hybrid-search.md#hybrid-does-not-automatically-beat-pure-vector).

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
benchmarks are usually English, general-domain, and their ordering does not
reliably transfer. Real counter-examples, each measured rather than argued:

- Query expansion (HyDE) regressing Hit@5 by tens of points on a domain corpus.
  On another, it found +1.1 pp more and **ranked worse** (MRR 0.557 → 0.536) at
  6× the hybrid latency — a reranking loss dressed as a recall win.
- A widely recommended reranker regressing Hit@5 double-digits on multilingual text.
- Translating an off-language query into a *keyword list* rather than a
  sentence: it helped the arm it targeted and finished **14 pp below doing
  nothing at all**.
- Raising top-k from 15 to 30: recall +5.4 pp, and the share of generated claims
  actually supported by a source fell 82.1 % → 78.8 %. Better retrieval, worse answer.
- The cheapest open embedding model beating the paid one on the target corpus,
  reversing the leaderboard order.

**Rule**: build a domain eval set ([evaluation.md](references/evaluation.md)),
then A/B each change. Adopt with ≥ +3 pp Hit@5 and p95 latency within budget;
reject otherwise.

Three traps that make an A/B lie, each covered in
[evaluation.md](references/evaluation.md#four-ways-a-measurement-lies-to-you):
measuring one retrieval arm instead of the pipeline; treating retrieval metrics
as the goal when an LLM consumes the results; and reading an offline sweep's
absolute numbers as a production forecast. Use **two** eval sets — generated
sentences and 1–3 word domain terms — because a change that helps one has
measured as hurting the other.

## Operators

| Operator | Distance | Use Case |
|----------|----------|----------|
| `<=>` | Cosine | Text embeddings (default) |
| `<->` | L2/Euclidean | Image embeddings |
| `<#>` | **Negative** inner product | Already-normalized vectors. Negative so that `ORDER BY` ascending still puts the closest first — negate it to read as a score |
| `<+>` | L1 / taxicab (`vector_l1_ops`, HNSW only) | Outlier-heavy features; `vector`, `halfvec`, `sparsevec` |
| `<~>` | Hamming (`bit_hamming_ops`) | Binary embeddings stored as `bit(n)` — compact and fast, coarser recall |
| `<%>` | Jaccard (`bit_jaccard_ops`, HNSW only) | Set-style binary embeddings as `bit(n)` |

## SQL Functions

**These are defined by this skill, not by pgvector.** Install them by running
the matching file from [scripts/](#scripts) — `match_documents` does not exist
in a database that has not had `semantic_search.sql` applied. Parameter names
below are the real ones from the scripts — Supabase `.rpc()` binds **by name**,
so a misspelled key fails at call time.

### Semantic Search — `scripts/semantic_search.sql`
- `match_documents(query_embedding, match_threshold, match_count)` - Basic search
- `match_documents_filtered(query_embedding, filter_metadata, match_threshold, match_count)` - With JSONB filter
- `match_documents_halfvec(query_embedding halfvec(3072), match_threshold, match_count)` - halfvec column variant
- `match_documents_dynamic(table_name, query_embedding, match_threshold, match_count)` - Same search against any table name
- `match_chunks(query_embedding, match_threshold, match_count)` - Search document chunks

### Fuzzy Search (pg_trgm) — `scripts/fuzzy_search.sql`
- `fuzzy_search_trigram(query_text, similarity_threshold, max_results)` - Trigram similarity search
- `autocomplete_search(search_prefix, max_results)` - Prefix + fuzzy autocomplete
- `hybrid_search_fuzzy_semantic(query_text, query_embedding, max_results, rrf_k)` - Fuzzy + vector RRF
- `weighted_fts_search(query_text, fts_language, max_results)` - FTS with title/content weighting

### Hybrid Search (FTS) — `scripts/hybrid_search_fts.sql`
- `hybrid_search_fts(query_embedding, query_text, match_count, rrf_k, fts_language)` - FTS + RRF
- `hybrid_search_weighted(query_embedding, query_text, match_count, semantic_weight, keyword_weight, fts_language)` - Linear combination
- `hybrid_search_fallback(query_embedding, query_text, match_count, rrf_k, fts_language)` - Graceful degradation (either input may be NULL)

These functions do not set `hnsw.ef_search`; the caller controls that query-time
tradeoff. Set it on the active connection (or with `SET LOCAL` in the same
transaction) before calling, or pgvector's default of 40 applies.
Their keyword arm also wraps content in `unaccent()` and computes the tsvector
per row; read the header of `hybrid_search_fts.sql` before using them on Finnish,
Swedish, German or Turkish text, or on a table that has a tsvector GIN index.

### Hybrid Search (BM25) — `scripts/hybrid_search_bm25.sql`
- `hybrid_search_bm25(query_embedding, query_text, match_count, rrf_k)` - BM25 + RRF
- `hybrid_search_bm25_highlighted(query_embedding, query_text, match_count, rrf_k)` - With snippet highlighting
- `hybrid_search_chunks_bm25(query_embedding, query_text, match_count, rrf_k)` - For RAG with chunks

## Re-ranking (Optional)

Two-stage retrieval improves precision: fast recall → precise rerank with a
cross-encoder. Use when results need higher precision and you have <50
candidates after initial retrieval.

**Key rule**: rerankers must be wrapped so a failure (missing key, HTTP error,
timeout) returns `null` and the caller falls back to original retrieval order
— never let a reranker outage break search.

For provider comparison, generic `Promise<T | null>` wrapper, and self-hosted
options, see [reranking.md](references/reranking.md).

## Multilingual / non-English content

Non-English corpora fail in specific, silent ways: the wrong FTS config skips
stemming, `unaccent` merges distinct Finnish/Swedish/German words, zero-width
characters glue onto tokens, every parser ANDs a long question into zero hits,
and English-derived chunk caps overflow the embedding endpoint. The rules and
fixes — FTS configs, prefix tsquery, synonym expansion, query translation,
ParadeDB stemmer casts, per-language indexing, cross-language RRF fusion — are
in [multilingual.md](references/multilingual.md). Read it before indexing
anything that is not English prose.

## References

- [fuzzy-search.md](references/fuzzy-search.md) - pg_trgm, fuzzy matching, LIKE/ILIKE, autocomplete, advanced FTS
- [paradedb.md](references/paradedb.md) - ParadeDB full-text search (Elasticsearch alternative)
- [vector-types.md](references/vector-types.md) - vector vs halfvec, dimensions, storage
- [indexing.md](references/indexing.md) - HNSW, IVFFlat, GIN parameters
- [hybrid-search.md](references/hybrid-search.md) - FTS, BM25, RRF algorithms
- [performance.md](references/performance.md) - Cold-start, memory, HNSW vs IVFFlat
- [evaluation.md](references/evaluation.md) - Eval-set construction, Hit@K / MRR, adoption thresholds, reranker/expansion benchmarking
- [reranking.md](references/reranking.md) - Two-stage retrieval, graceful fallback, when rerankers regress
- [multilingual.md](references/multilingual.md) - FTS configs and unaccent rules, invisible characters, prefix tsquery, query translation, per-language indexing, cross-language RRF

## Scripts

- [setup.sql](scripts/setup.sql) - Extension and table setup
- [semantic_search.sql](scripts/semantic_search.sql) - Semantic search functions
- [hybrid_search_fts.sql](scripts/hybrid_search_fts.sql) - FTS hybrid functions
- [hybrid_search_bm25.sql](scripts/hybrid_search_bm25.sql) - BM25 hybrid functions
- [fuzzy_search.sql](scripts/fuzzy_search.sql) - pg_trgm fuzzy search, autocomplete, weighted FTS
- [indexes.sql](scripts/indexes.sql) - Index creation scripts
- [embeddings.ts](scripts/embeddings.ts) - Embedding generation helpers (TypeScript)

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
| Long plain-language question returns 0 keyword hits | Parser ANDs every term | For queries without explicit `OR`, quotes, or `-`, parse with `plainto_tsquery`, rewrite `&`→`\|`, and rank with `ts_rank_cd` — see hybrid-search.md |
| FTS misses a word that is visibly there | Invisible character (U+200B etc.) glued to the token blocks stemming | Strip zero-width characters at ingest and query time |
| `could not determine data type of parameter $N` | A placeholder never appears in this variant's SQL (e.g. vector-only vs keyword-only mode sharing one numbering) | Give each query variant its own statement and parameter numbering |
| Memory error on index build | maintenance_work_mem too low | Increase to 2GB+ |
| "Cosine similarity" > 1 | `<#>` used in the cosine formula | `1 - (a <=> b)` is cosine similarity and is bounded in [-1, 1] whatever the magnitudes — `<=>` divides by them. `<#>` returns the **negative inner product**, unbounded: for `[3,4]` and `[6,8]` it is `-50`, so `1 - (a <#> b)` is `51`. Use `<=>` for cosine, or `(a <#> b) * -1` for inner product on already-normalized vectors |
| Slow inserts | Index overhead | Batch inserts, consider IVFFlat |
| Fuzzy search slow | Missing trigram index | `CREATE INDEX USING gin (col gin_trgm_ops)` |
| ILIKE '%x%' slow | No pg_trgm GIN index | Enable pg_trgm + create GIN trigram index |
| `%` operator error | pg_trgm not installed | `CREATE EXTENSION IF NOT EXISTS pg_trgm` |

## Compatibility

- **pgvector**: 0.8.6+ recommended as the safe floor (as of 2026-09). Feature history: 0.7.0 added halfvec/bit/sparsevec, 0.8.0 added iterative scans. Correctness history: 0.6.0–0.8.1 carry a parallel-HNSW-build buffer overflow (CVE-2026-3172 — leaks data from other relations or crashes the server), 0.8.2 fixed it, 0.8.3 fixed possible HNSW index corruption during vacuum, 0.8.4 fixed further HNSW vacuum errors, and 0.8.6 fixed an IVFFlat build integer wraparound on 32-bit systems (CVE-2026-18022). Verify current state in the [CHANGELOG](https://github.com/pgvector/pgvector/blob/master/CHANGELOG.md) — the GitHub Releases tab is empty, releases ship as tags.
- **pg_search**: Since 0.25.0 pg_search depends on pgvector's `vector` type — install pgvector first. Check [ParadeDB releases](https://github.com/paradedb/paradedb/releases) for latest.
- **PostgreSQL**: pgvector supports 13+; pg_search ships prebuilt binaries for 15+. Prefer the newest major your host offers.

## Related Skills

| Need | Skill |
|------|-------|
| General Postgres performance, indexes, RLS, connection pooling | `/supabase-postgres-best-practices` |
| Chatbot orchestration, session DB, tool calls, HITL, feedback | `/nextjs-chatbot` |
| AI SDK usage for embeddings and retrieval | `/ai-sdk` |

For ParadeDB-specific questions, always apply the Documentation Fetch Policy in [references/paradedb.md](references/paradedb.md) — live docs at `https://www.paradedb.com/docs/llms-full.txt` are the authoritative source.

## External Documentation

### Core
- [pgvector GitHub](https://github.com/pgvector/pgvector) - Official extension, latest features
- [PostgreSQL FTS](https://www.postgresql.org/docs/current/textsearch.html) - Built-in full-text search

### Embedding providers
- [OpenAI Embeddings](https://developers.openai.com/api/docs/guides/embeddings) - model list + dimensions
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
- [ParadeDB pg_search](https://www.paradedb.com/docs/documentation/getting-started/install) - BM25 extension documentation
- [ParadeDB AI Docs](https://www.paradedb.com/docs/llms-full.txt) - Fetch for latest ParadeDB API (always current)
