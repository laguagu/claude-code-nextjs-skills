# pgvector: types, indexes and query shapes

Read when choosing a column type or index, tuning recall or latency, or when a
vector query returns too few rows or ignores its index. The pgvector
[README](https://github.com/pgvector/pgvector) is the reference for syntax.

## Contents

- [Column type and dimension limits](#column-type-and-dimension-limits)
- [Tuning HNSW against exact search](#tuning-hnsw-against-exact-search)
- [When the planner skips the index](#when-the-planner-skips-the-index)
- [Filters, thresholds and too few rows](#filters-thresholds-and-too-few-rows)
- [Settings and connection poolers](#settings-and-connection-poolers)
- [Builds, cold starts and IVFFlat](#builds-cold-starts-and-ivfflat)
- [Distance operators](#distance-operators)

## Column type and dimension limits

Indexable dimensions: `vector` 2,000, `halfvec` 4,000, `bit` 64,000. All types
store up to 16,000.

| Dimensions N | Column | Index |
| --- | --- | --- |
| N ≤ 2,000 | `vector(N)` | `vector_cosine_ops` |
| 2,000 < N ≤ 4,000 | `vector(N)`, or `halfvec(N)` when storage is tight | halfvec expression index |
| N > 4,000 | `vector(N)` | binary quantization to `bit`, or a Matryoshka `subvector` |

Keeping full precision in the column and indexing a cast leaves room to
rescore at full precision or change the index later. The query must repeat the index expression exactly,
cast included, or the planner cannot use the index:

```sql
CREATE INDEX ON docs USING hnsw ((embedding::halfvec(3072)) halfvec_cosine_ops);
SELECT id FROM docs ORDER BY embedding::halfvec(3072) <=> $1::halfvec(3072) LIMIT 10;
```

Truncate dimensions (`subvector`, or the provider's dimensions parameter) only
for models trained for it (Matryoshka); on other models recall degrades badly.
A truncated vector is no longer unit length: `l2_normalize` it before using
inner product or L2 as if it were. Cosine does not care.

## Tuning HNSW against exact search

pgvector's defaults are `m = 16`, `ef_construction = 64` and
`hnsw.ef_search = 40`. Keep exact search (no index) as the recall baseline and
raise `ef_search` until recall on your eval set stops moving.

Measured on ~54,000 vectors and 92 graded questions: the default 40 gave
Recall@15 73.9 %, 100 gave 75.0 % (identical to exact search, 3.4× faster), and
400 found the same rows more slowly. The default costs recall silently: no
warning, plausible results. Re-check when the corpus grows by an order of
magnitude.

## When the planner skips the index

`ef_search` does nothing if the plan has no index scan, and nothing warns you.
Check the plan node, not the latency:

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id FROM chunks ORDER BY embedding <=> $1 LIMIT 60;
-- want "Index Scan using ..._hnsw"; "Seq Scan" means exact search
```

A seq scan can be the right call. On 37,440 vectors with a 283 MB graph on a
small instance, forcing the index with `enable_seqscan = off` made the query
four times slower (1,417 ms against 356 ms): the graph did not fit in memory.
Whether the graph fits decides this, not the row count. When results come from
a seq scan they are exact, so recall numbers are an upper bound and `ef_search`
experiments are meaningless.

## Filters, thresholds and too few rows

- **An HNSW scan returns at most `hnsw.ef_search` rows** (40 by default). A
  `LIMIT` above it, or a `WHERE` that discards candidates, silently returns
  fewer rows: a filter matching 10 % of rows leaves about 4. Iterative scans
  (0.8.0+) keep scanning until enough rows pass. They are off by default:
  `SET hnsw.iterative_scan = relaxed_order` (or `strict_order`; IVFFlat has only
  `relaxed_order`). Scans stop at `hnsw.max_scan_tuples` (20,000) or
  `ivfflat.max_probes`.
- **A few fixed filter values**: a partial index per value. **Many values or
  tenants**: partition. A shared index lets one tenant's vectors affect another
  tenant's recall and speed.
- **Distance thresholds go outside a materialized CTE**, other filters inside
  it. Inline, the executor keeps scanning the index past the threshold:

  ```sql
  WITH nearest AS MATERIALIZED (
    SELECT id, embedding <=> $1 AS distance FROM docs
    WHERE tenant_id = $2 ORDER BY distance LIMIT 10
  ) SELECT * FROM nearest WHERE distance < 0.3 ORDER BY distance + 0;
  ```

  `+ 0` makes Postgres 17+ actually re-sort a `relaxed_order` result.
- **NULL vectors are never indexed, nor zero vectors under cosine** (their
  cosine distance is NaN). Do not warm up with a zero vector.

## Settings and connection poolers

`SET` is per connection. Behind a transaction pooler (PgBouncer, Supavisor in
transaction mode) the next statement may run on another connection, so use
`SET LOCAL` inside the same transaction, or attach the setting to a function
(`CREATE FUNCTION ... SET hnsw.iterative_scan = relaxed_order`).

## Builds, cold starts and IVFFlat

- Load data first, then build. HNSW builds are much faster while the graph fits
  in `maintenance_work_mem`; pgvector prints a NOTICE when it stops fitting.
  Raise it within the host's memory. In Docker, `--shm-size` must be at least
  that large or parallel builds fail.
- A cold query reads from disk only the index pages it visits; measure cold and
  warm runs separately. `pg_prewarm` loads a whole index, so check its size
  against memory first.
- IVFFlat trades recall for memory and build time. Build it only when the table
  holds representative data: lists learned from an empty or tiny table silently
  return too few rows. Starting points: `lists = rows / 1000` up to 1M rows,
  `sqrt(rows)` above, `ivfflat.probes = sqrt(lists)`.

## Distance operators

| Operator | Distance | Index ops |
| --- | --- | --- |
| `<=>` | cosine | `vector_cosine_ops` |
| `<->` | L2 | `vector_l2_ops` |
| `<#>` | negative inner product | `vector_ip_ops` |
| `<+>` | L1 | `vector_l1_ops` (HNSW) |
| `<~>` / `<%>` | Hamming / Jaccard on `bit` | `bit_hamming_ops` / `bit_jaccard_ops` |

`<#>` is negated so that ascending `ORDER BY` puts the best match first; negate
it to read a score. `1 - (a <=> b)` is cosine similarity. `1 - (a <#> b)` is
not: for `[3,4]` and `[6,8]` it is 51. halfvec uses the same operators with
`halfvec_*_ops`.
