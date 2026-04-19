# Indexing Guide

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

Same pattern for IVFFlat: `SET ivfflat.iterative_scan = on`.

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
| `lists` | `sqrt(rows)` or `rows / 1000` |
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
