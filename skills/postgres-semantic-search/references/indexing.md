# Indexing Guide

## Contents

- [Index Selection](#index-selection)
- [HNSW](#hnsw-hierarchical-navigable-small-world) — parameters, settings, **`ef_search` default**, operator classes, `iterative_scan`, halfvec
- [IVFFlat](#ivfflat)
- [GIN Indexes (Full-Text Search)](#gin-indexes-full-text-search) — FTS, weighted tsvector, JSONB, arrays
- [Partial Indexes](#partial-indexes)
- [Index Maintenance](#index-maintenance)
- [Concurrent Index Creation](#concurrent-index-creation)
- [Build Time Estimates](#build-time-estimates)

## Index Selection

| Documents | Index Type | Notes |
|-----------|-----------|-------|
| < 10,000 | None | Sequential scan is fast enough |
| 10k - 1M | HNSW | Best recall, fast queries |
| > 1M | IVFFlat or HNSW | IVFFlat saves memory |

## HNSW (Hierarchical Navigable Small World)

Best for most production workloads.

### Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `m` | 16 | 4-64 | Connections per layer. Higher = better recall, larger index |
| `ef_construction` | 64 | 4-400 | Build-time quality. Higher = better index, slower build |
| `ef_search` | 40 | 1-1000 | Query-time depth. Higher = better recall, slower queries |

### Recommended Settings

**Development:**
```sql
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
```

**Production (< 100k vectors):**
```sql
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 200);

SET hnsw.ef_search = 100;
```

**Production (100k - 1M vectors):**
```sql
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 24, ef_construction = 200);

SET hnsw.ef_search = 100;
```

### The `ef_search` default costs recall silently

Check this before anything else if you run your own pgvector search. The
default of 40 looks like it works — no warning, no error, plausible results —
and it quietly returns fewer correct rows than the same index would at 100.

Measured on a ~54,000-vector corpus, 92 graded questions, HNSW:

| `hnsw.ef_search` | Recall@15 | MRR | Median latency |
| --- | ---: | ---: | ---: |
| 10 | 72.8 % | 0.518 | 73 ms |
| **40** *(pgvector default)* | 73.9 % | 0.546 | 70 ms |
| **100** | **75.0 %** | **0.557** | **69 ms** |
| 400 | 75.0 % | 0.557 | 76 ms |
| *exact search, no index* | 75.0 % | 0.557 | 233 ms |

Three things worth taking from that:

- **The default costs ~1.1 pp of recall for no latency saving** at this scale.
- **At 100 the index is free**: it returned exactly what exhaustive search
  returned, 3.4× faster. "Approximate" does not have to mean "worse".
- **Past 100 you buy nothing.** 400 found the same rows and was slower. Tune
  up until recall stops moving, then stop.

Set it per connection alongside `hnsw.iterative_scan` rather than per query,
and re-check it whenever the corpus grows by an order of magnitude — the right
value is a function of index size, not a constant.

### Operator Classes

| Operator | Class | Distance |
|----------|-------|----------|
| `<=>` | `vector_cosine_ops` | Cosine (most common) |
| `<->` | `vector_l2_ops` | Euclidean/L2 |
| `<#>` | `vector_ip_ops` | Inner product |

### Filtered HNSW queries — `iterative_scan` (pgvector 0.8+)

When you combine HNSW search with WHERE filters (categories, tenant IDs, date
ranges), the index returns its top-N candidates *first* and the filter is
applied *after*. If filters are selective, you can end up with fewer than `LIMIT`
matching rows.

```sql
-- Problematic when filter is selective: returns < 10 rows even if more match
SELECT * FROM documents
WHERE category = 'rare'
ORDER BY embedding <=> query_vec
LIMIT 10;
```

**Fix:** enable iterative scan so HNSW keeps fetching candidates until LIMIT is
satisfied (or the index is exhausted):

```sql
-- Session-level (one-off connections, scripts)
SET hnsw.iterative_scan = relaxed_order;  -- fast, slight reordering near boundary
-- or
SET hnsw.iterative_scan = strict_order;   -- preserves exact distance order, slower

-- Function-level (preferred for stable behavior in stored procedures)
CREATE OR REPLACE FUNCTION search_filtered(...)
  RETURNS TABLE (...)
  LANGUAGE sql STABLE
  SET hnsw.iterative_scan = 'relaxed_order'
AS $$ ... $$;
```

**When to enable:**
- WHERE filters typically reduce candidate pool by > 50 %
- Multi-tenant apps (every query filters by `tenant_id`)
- Queries that combine semantic search with metadata filters

**When NOT needed:**
- Unfiltered semantic search across all rows
- Filters that match > 80 % of rows (HNSW finds enough naturally)

Same pattern for IVFFlat, except it has no `strict_order`:
`SET ivfflat.iterative_scan = relaxed_order`.

Iterative scan is **off by default** — nothing happens unless you set it. Scans
stop at `hnsw.max_scan_tuples` (20,000 by default) or `ivfflat.max_probes`.

### halfvec Operator Classes

| Operator | Class |
|----------|-------|
| `<=>` | `halfvec_cosine_ops` |
| `<->` | `halfvec_l2_ops` |
| `<#>` | `halfvec_ip_ops` |

## IVFFlat

Use for very large datasets where memory is critical.

### Parameters

| Parameter | Recommendation |
|-----------|---------------|
| `lists` | `rows / 1000` for up to 1M rows; `sqrt(rows)` for over 1M rows |
| `probes` | `sqrt(lists)` at query time |

```sql
-- For 1M rows: lists = 1000
CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 1000);

-- Query time (higher probes = better recall)
SET ivfflat.probes = 32;
```

**Trade-off:** Faster build, lower recall than HNSW.

## GIN Indexes (Full-Text Search)

### PostgreSQL FTS

```sql
-- Basic FTS index
CREATE INDEX ON documents USING GIN (to_tsvector('simple', content));

-- Language-specific (with stemming)
CREATE INDEX ON documents USING GIN (to_tsvector('english', content));
CREATE INDEX ON documents USING GIN (to_tsvector('finnish', content));
```

### Weighted tsvector (pre-computed)

```sql
-- Add weighted column
ALTER TABLE documents ADD COLUMN tsv tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(title,'')), 'A') ||
    setweight(to_tsvector('english', coalesce(content,'')), 'B')
) STORED;

-- Index the weighted column
CREATE INDEX ON documents USING GIN (tsv);
```

> [!WARNING]
> **Verify in the deployed database that the column really is generated.**
> A generated tsvector that has silently become a plain column is the worst
> failure mode in this skill: no error, no exception, every row simply holds
> `NULL` and the keyword half of hybrid search matches nothing, forever. In
> one production system this ran for roughly six months — "hybrid" search
> was pure vector search and nobody noticed, because it still returned
> results.
>
> ORM migration generators are the usual cause: a regenerated schema can
> emit the column without its `GENERATED ALWAYS AS` expression, and nothing
> in the repo looks wrong.
>
> ```sql
> -- attgenerated must be 's' (stored). Empty means a plain column.
> SELECT attrelid::regclass AS tbl, attname, attgenerated
> FROM pg_attribute
> WHERE attname = 'tsv' AND NOT attisdropped;
>
> -- And the values have to actually be there.
> SELECT count(*) AS rows, count(tsv) AS populated FROM documents;
> ```
>
> Postgres has no `ALTER COLUMN ... SET GENERATED` for stored generated
> columns, so repairing one means `DROP COLUMN` + `ADD COLUMN ... GENERATED`,
> which also drops its indexes. Cheap, but it has to be a deliberate
> migration.
>
> The check that needs no database access at all: run the same literal term
> through hybrid search and through pure vector search. Identical result
> lists mean the keyword arm is dead.

### JSONB Metadata

```sql
CREATE INDEX ON documents USING GIN (metadata);

-- Query: WHERE metadata @> '{"category": "news"}'
```

### Array Columns

```sql
CREATE INDEX ON documents USING GIN (tags);

-- Query: WHERE tags && ARRAY['tag1', 'tag2']
```

## Partial Indexes

Index only rows matching a condition:

```sql
-- Index only news category
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
WHERE metadata->>'category' = 'news';

-- Index only non-null embeddings
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
WHERE embedding IS NOT NULL;
```

## Index Maintenance

```sql
-- Reindex (if performance degrades)
REINDEX INDEX documents_embedding_hnsw_idx;

-- Update statistics
ANALYZE documents;

-- Check index size
SELECT pg_size_pretty(pg_relation_size('documents_embedding_hnsw_idx'));

-- Check if index is used
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM documents ORDER BY embedding <=> '[...]'::vector LIMIT 10;
```

## Concurrent Index Creation

Create indexes without blocking writes:

```sql
CREATE INDEX CONCURRENTLY documents_embedding_idx
ON documents USING hnsw (embedding vector_cosine_ops);
```

**Note:** Takes longer but doesn't lock the table.

## Build Time Estimates

| Vectors | HNSW (m=16) | IVFFlat (lists=100) |
|---------|-------------|---------------------|
| 10k | ~30 sec | ~10 sec |
| 100k | ~5 min | ~1 min |
| 1M | ~1 hour | ~10 min |

Build times vary by hardware. HNSW is slower to build but faster to query.
