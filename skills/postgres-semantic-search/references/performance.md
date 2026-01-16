# Performance Optimization

## Cold-Start Optimization

HNSW indexes load into memory on first query. This can take 30-60+ seconds for large indexes.

### Preload Index

```sql
-- Force index scan on startup
SELECT COUNT(*) FROM (
    SELECT 1 FROM documents
    ORDER BY embedding <=> '[0,0,...,0]'::vector(1536)
    LIMIT 1
) t;
```

Add to application startup or cron job.

### HNSW Parameter Tuning

For faster cold-start:

```sql
-- Higher m = larger index, but better graph quality
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 24, ef_construction = 100);

-- Higher ef_search = better recall, but slower queries
SET hnsw.ef_search = 80;
```

**Benchmark for your data** - optimal values depend on dataset size.

## Memory Configuration

### PostgreSQL Settings

```ini
# postgresql.conf

# Shared memory for caching (25% of RAM)
shared_buffers = 4GB

# Query planner estimate (75% of RAM)
effective_cache_size = 12GB

# Per-query work memory
work_mem = 256MB

# Maintenance operations (index builds)
maintenance_work_mem = 2GB
```

### Session-Level Tuning

```sql
-- Increase for complex queries
SET work_mem = '512MB';

-- Higher ef_search for better recall
SET hnsw.ef_search = 200;

-- More IVFFlat probes
SET ivfflat.probes = 20;
```

## Query Optimization

### Pre-filtering vs Post-filtering

**Pre-filtering (filter first, then vector search):**

```sql
-- Good when filter is selective (returns few rows)
SELECT * FROM documents
WHERE metadata->>'category' = 'news'  -- Filter first
ORDER BY embedding <=> query_vec
LIMIT 10;
```

**Post-filtering (vector search first, then filter):**

```sql
-- Good when filter is broad
SELECT * FROM (
    SELECT * FROM documents
    ORDER BY embedding <=> query_vec
    LIMIT 100  -- Get more candidates
) sub
WHERE metadata->>'category' = 'news'  -- Then filter
LIMIT 10;
```

### pgvector 0.8.0+ Iterative Scans

pgvector 0.8.0+ has iterative index scans that automatically handle filtering better:

```sql
-- Just write the query naturally
SELECT * FROM documents
WHERE embedding IS NOT NULL
  AND metadata->>'category' = 'news'
ORDER BY embedding <=> query_vec
LIMIT 10;
```

The planner will choose the best strategy.

### Partial Indexes for Filtered Queries

If you frequently filter by the same criteria:

```sql
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
WHERE metadata->>'category' = 'news';

-- Query will use this smaller, faster index
SELECT * FROM documents
WHERE metadata->>'category' = 'news'
ORDER BY embedding <=> query_vec
LIMIT 10;
```

## Batch Operations

### Batch Embedding Insertion

```sql
-- Insert multiple rows at once
INSERT INTO documents (content, embedding)
VALUES
    ('text1', '[...]'::vector),
    ('text2', '[...]'::vector),
    ...
    ('text50', '[...]'::vector);
```

### Batch Queries

```sql
-- Multiple queries in one round-trip
SELECT d.*, q.query_id
FROM unnest(ARRAY[
    '[...]'::vector,
    '[...]'::vector
]) WITH ORDINALITY AS q(vec, query_id)
CROSS JOIN LATERAL (
    SELECT * FROM documents
    ORDER BY embedding <=> q.vec
    LIMIT 10
) d;
```

## Connection Pooling

Use connection pooling to avoid connection overhead:

- **PgBouncer** - External pooler
- **Supabase Pooler** - Managed pooler
- **Application-level** - Most ORMs have pooling

```
# PgBouncer recommended settings
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
```

## Monitoring

### Query Performance

```sql
-- Enable timing
\timing on

-- Explain analyze
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM documents
ORDER BY embedding <=> '[...]'::vector
LIMIT 10;
```

### Index Usage

```sql
-- Check if index is being used
SELECT
    indexrelname AS index_name,
    idx_scan AS scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE relname = 'documents';
```

### Table Size

```sql
SELECT
    pg_size_pretty(pg_total_relation_size('documents')) AS total,
    pg_size_pretty(pg_relation_size('documents')) AS table,
    pg_size_pretty(pg_indexes_size('documents')) AS indexes;
```

## Scaling Strategies

### Vertical Scaling
- More RAM = larger indexes in memory
- Faster CPU = faster distance calculations
- NVMe SSD = faster cold-start

### Horizontal Scaling (Advanced)
- **Read replicas** - Distribute read queries
- **Citus** - Distributed PostgreSQL (pg_search 0.20+ compatible)
- **Partitioning** - Split by date/category

### When to Scale

| Symptom | Solution |
|---------|----------|
| Cold-start > 30s | More RAM, preload index |
| Query latency > 100ms | Tune ef_search, add RAM |
| Insert latency high | Batch inserts, IVFFlat |
| Index build > 1 hour | More maintenance_work_mem |

## Benchmarking

Always benchmark with your actual data:

```sql
-- Simple benchmark
\timing on
SELECT * FROM documents ORDER BY embedding <=> '[...]'::vector LIMIT 10;
-- Run multiple times, ignore first (cold cache)

-- With EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM documents ORDER BY embedding <=> '[...]'::vector LIMIT 10;
```

Compare:
- Different index types (HNSW vs IVFFlat)
- Different parameters (m, ef_construction, ef_search)
- With and without filters
