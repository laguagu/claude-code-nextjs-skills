# Hybrid Search Guide

Hybrid search combines semantic (vector) search with keyword search for better results.

## Why Hybrid Search?

| Search Type | Strengths | Weaknesses |
|-------------|-----------|------------|
| **Semantic** | Understands meaning, synonyms | May miss exact terms |
| **Keyword** | Precise term matching | No semantic understanding |
| **Hybrid** | Best of both | More complex |

**Example:** Query "PostgreSQL 17.2 release notes"
- Semantic: Finds "database version updates" (related meaning)
- Keyword: Finds exact "PostgreSQL 17.2" matches
- Hybrid: Finds both, ranks appropriately

## Keyword Search Options

### Option 1: PostgreSQL FTS (Built-in)

No extra extensions needed.

```sql
-- Create index
CREATE INDEX ON documents USING GIN (to_tsvector('simple', content));

-- Search
SELECT * FROM documents
WHERE to_tsvector('simple', content) @@ plainto_tsquery('simple', 'search terms')
ORDER BY ts_rank(to_tsvector('simple', content), plainto_tsquery('simple', 'search terms')) DESC;
```

**Language options:**
- `'simple'`: No stemming, basic tokenization. Good for mixed languages.
- `'english'`: English stemming. "running" matches "run".
- `'finnish'`: Finnish stemming. "karttoja" matches "kartta".

### Option 2: pg_search BM25

Better ranking than ts_rank. Requires `pg_search` extension.

```sql
-- Install
CREATE EXTENSION pg_search;

-- Create BM25 index
CALL paradedb.create_bm25(
    index_name => 'documents_bm25',
    table_name => 'documents',
    key_field => 'id',
    text_fields => paradedb.field('content')
);

-- Search
SELECT id, paradedb.score(id) AS score
FROM documents
WHERE id @@@ paradedb.match('content', 'search terms')
ORDER BY score DESC;
```

**BM25 vs ts_rank:**
- BM25 considers corpus statistics (IDF)
- Better for varying document lengths
- Generally more accurate relevance

## Result Fusion Methods

### RRF (Reciprocal Rank Fusion)

Combines rankings without needing normalized scores.

```
RRF_score = 1/(k + rank_semantic) + 1/(k + rank_keyword)
```

Where `k` = 60 (constant, default)

```sql
WITH semantic AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> query_vec) AS rank
    FROM documents LIMIT 100
),
keyword AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank(...) DESC) AS rank
    FROM documents WHERE ... LIMIT 100
)
SELECT
    COALESCE(s.id, k.id) AS id,
    (COALESCE(1.0/(60 + s.rank), 0) + COALESCE(1.0/(60 + k.rank), 0)) AS rrf_score
FROM semantic s
FULL OUTER JOIN keyword k ON s.id = k.id
ORDER BY rrf_score DESC;
```

**Pros:** No score normalization needed, robust.
**Cons:** Ignores actual score magnitudes.

### Linear Weighting

Combines normalized scores with weights.

```sql
combined_score = w_semantic * semantic_score + w_keyword * keyword_score
```

**Typical weights:**
- Semantic-heavy: 0.7 / 0.3
- Balanced: 0.5 / 0.5
- Keyword-heavy: 0.3 / 0.7

```sql
-- Normalize keyword scores to 0-1 range
WITH keyword_normalized AS (
    SELECT id, score / MAX(score) OVER () AS norm_score
    FROM keyword_results
)
SELECT
    s.id,
    0.6 * s.similarity + 0.4 * COALESCE(k.norm_score, 0) AS combined
FROM semantic s
LEFT JOIN keyword_normalized k ON s.id = k.id
ORDER BY combined DESC;
```

**Pros:** Tunable per domain.
**Cons:** Requires score normalization.

## Ready-to-Use Functions

### FTS + RRF (No extra extensions)

See `scripts/hybrid_search_fts.sql`:
- `hybrid_search_fts()` - Basic hybrid with RRF
- `hybrid_search_weighted()` - With tunable weights
- `hybrid_search_fallback()` - Graceful degradation

### BM25 + RRF (With pg_search)

See `scripts/hybrid_search_bm25.sql`:
- `hybrid_search_bm25()` - Basic BM25 hybrid
- `hybrid_search_bm25_highlighted()` - With snippet highlighting
- `hybrid_search_chunks_bm25()` - For RAG with chunks

## Chunk-Based Search (RAG)

For large documents split into chunks:

1. Search chunks, not documents
2. Deduplicate by document (keep best chunk)
3. Return chunk + parent document info

```sql
WITH chunk_results AS (
    SELECT
        c.id AS chunk_id,
        c.document_id,
        c.content,
        ROW_NUMBER() OVER (ORDER BY c.embedding <=> query_vec) AS rank,
        ROW_NUMBER() OVER (PARTITION BY c.document_id ORDER BY c.embedding <=> query_vec) AS doc_rank
    FROM chunks c
)
SELECT * FROM chunk_results WHERE doc_rank = 1  -- Best chunk per document
ORDER BY rank LIMIT 10;
```

## Best Practices

1. **Start with FTS + RRF** - No extra dependencies
2. **Add BM25 if needed** - Better ranking for keyword-heavy queries
3. **Use RRF for simplicity** - Works well without tuning
4. **Tune weights for your domain** - If RRF isn't optimal
5. **Index both** - Vector index + GIN/BM25 index
6. **Consider language** - Use appropriate FTS language config

## Choosing Search Method

```
Query type?
├─ Conceptual/semantic → Pure vector search
├─ Exact terms/names → Pure keyword search
└─ Mixed/unknown → Hybrid search
    ├─ Simple setup → FTS + RRF (no extra extensions)
    ├─ Better ranking → BM25 + RRF (pg_search extension)
    └─ Full-featured → ParadeDB (Elasticsearch alternative)
```

## ParadeDB (Full-Featured Alternative)

For comprehensive Elasticsearch-like features including BM25 ranking, faceted search, highlighting, fuzzy search, and aggregations, see [paradedb.md](paradedb.md).

ParadeDB is ideal when you need:
- Production-grade BM25 ranking (better than ts_rank)
- Built-in highlighting with `pdb.snippet()`
- Faceted queries with `pdb.agg()`
- Fuzzy search with typo tolerance
- Zero ETL - runs as Postgres extension or logical replica
