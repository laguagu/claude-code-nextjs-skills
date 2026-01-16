# ParadeDB - Elasticsearch Alternative for PostgreSQL

ParadeDB is a YC S23 company with 400,000+ deployments. Used in production by Alibaba Cloud, Bilt Rewards, and others.

## Why ParadeDB?

| Feature | Postgres FTS | Elasticsearch | ParadeDB |
|---------|--------------|---------------|----------|
| BM25 ranking | No (ts_rank) | Yes | Yes |
| ACID | Yes | No | Yes |
| Zero ETL | - | Requires ETL | Yes |
| Facets | Manual | Yes | Yes |
| Highlighting | Manual | Yes | Yes |
| Fuzzy search | Weak | Yes | Yes |
| JOINs | Yes | No | Yes |

**Key benefits:**
- Zero ETL - runs as Postgres extension or logical replica
- Full ACID compliance with read-after-write guarantees
- Standard SQL with custom search operators
- Handles updates/deletes well (unlike Elastic)

## Installation

### Docker (includes Postgres 18 + pgvector + pg_search)

```bash
docker run -d --name paradedb \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=mydatabase \
  -v paradedb_data:/var/lib/postgresql/ \
  -p 5432:5432 \
  paradedb/paradedb:latest

# Connect
docker exec -it paradedb psql -U myuser -d mydatabase -W
```

### Neon (AWS regions, PostgreSQL 17+)

```sql
CREATE EXTENSION pg_search;
```

### Self-hosted Postgres

```sql
-- Install pg_search extension
CREATE EXTENSION pg_search;
```

## BM25 Index

BM25 index is a **covering index** - include all columns you'll search, filter, sort, or aggregate.

```sql
-- Basic index
CREATE INDEX search_idx ON documents
USING bm25 (id, content, title, category, metadata)
WITH (key_field='id');

-- With tokenizer + stemmer
CREATE INDEX search_idx ON documents
USING bm25 (
    id,
    (content::pdb.unicode_words('stemmer=english')),
    (title::pdb.ngram(3,3)),
    category
)
WITH (key_field='id');
```

**Key field requirements:**
- Must have UNIQUE constraint (usually PRIMARY KEY)
- Must be first in column list
- If text, must be untokenized

### Available Tokenizers

| Tokenizer | Use Case |
|-----------|----------|
| `pdb.unicode` | General text (default) |
| `pdb.unicode_words` | Word-level with stemmers |
| `pdb.icu` | Multi-language |
| `pdb.ngram(min, max)` | Partial matching, typo tolerance |
| `pdb.simple` | Basic whitespace |

### Tokenizer Parameters

```sql
-- Remove emojis from text before indexing
(content::pdb.unicode_words('stemmer=english', 'remove_emojis=true'))
```

### Stemmer Languages

```sql
-- English
(content::pdb.unicode_words('stemmer=english'))

-- Finnish
(content::pdb.unicode_words('stemmer=finnish'))

-- Multiple token filters
(content::pdb.simple('stemmer=english', 'ascii_folding=true'))
```

### JSON Field Indexing

JSONB fields are automatically indexed with sub-fields. Target specific sub-fields with tokenizers:

```sql
CREATE INDEX ON documents USING bm25 (
    id,
    metadata,  -- Auto-indexes all sub-fields
    ((metadata->>'title')::pdb.unicode_words('stemmer=english')),
    ((metadata->>'tags')::pdb.ngram(2,3))
)
WITH (key_field='id');
```

## Search Operators

### Match Disjunction (OR)

```sql
-- Find documents containing "semantic" OR "search"
SELECT * FROM documents
WHERE content ||| 'semantic search'
ORDER BY pdb.score(id) DESC;
```

### Match Conjunction (AND)

```sql
-- Find documents containing "semantic" AND "search"
SELECT * FROM documents
WHERE content &&& 'semantic search'
ORDER BY pdb.score(id) DESC;
```

### Exact JSON Match

```sql
-- Exact match on JSON field
SELECT * FROM documents
WHERE metadata->>'category' === 'technology';
```

## BM25 Scoring

```sql
SELECT
    id,
    content,
    pdb.score(id) AS relevance
FROM documents
WHERE content ||| 'search query'
ORDER BY relevance DESC
LIMIT 10;
```

## Highlighting (Snippets)

```sql
SELECT
    id,
    pdb.snippet(content) AS highlighted_content,
    pdb.score(id) AS score
FROM documents
WHERE content ||| 'semantic search'
ORDER BY score DESC;

-- Output: "This is about <b>semantic</b> <b>search</b> in databases"
```

## Faceted Queries (Aggregations)

Single query returns both results and aggregates:

```sql
SELECT
    content,
    pdb.score(id) AS score,
    pdb.agg('{"value_count": {"field": "id"}}') OVER () AS total_matches
FROM documents
WHERE content ||| 'search'
ORDER BY score DESC
LIMIT 10;

-- Output includes total_matches: {"value": 42.0}
```

## Boolean Queries

```sql
-- Complex boolean logic
SELECT * FROM documents
WHERE id @@@ paradedb.boolean(
    must => ARRAY[paradedb.match('content', 'postgresql')],
    should => ARRAY[paradedb.match('content', 'vector')],
    must_not => ARRAY[paradedb.match('content', 'deprecated')]
)
ORDER BY pdb.score(id) DESC;
```

## Fuzzy Search

```sql
-- Typo-tolerant search (edit distance 2)
SELECT * FROM documents
WHERE id @@@ paradedb.fuzzy('content', 'postgre', distance => 2)
ORDER BY pdb.score(id) DESC;
```

## Phrase Search

```sql
-- Exact phrase matching
SELECT * FROM documents
WHERE id @@@ paradedb.phrase('content', ARRAY['vector', 'database'])
ORDER BY pdb.score(id) DESC;
```

## Hybrid Search (BM25 + pgvector)

Combine BM25 full-text search with vector similarity using RRF:

```sql
WITH bm25_results AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY pdb.score(id) DESC) AS rank
    FROM documents
    WHERE content ||| 'semantic search'
    LIMIT 100
),
vector_results AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> query_vec) AS rank
    FROM documents
    ORDER BY embedding <=> query_vec
    LIMIT 100
)
SELECT
    COALESCE(b.id, v.id) AS id,
    (COALESCE(1.0/(60 + b.rank), 0) + COALESCE(1.0/(60 + v.rank), 0)) AS rrf_score
FROM bm25_results b
FULL OUTER JOIN vector_results v ON b.id = v.id
ORDER BY rrf_score DESC
LIMIT 10;
```

## Filtering with Search

```sql
-- Combine BM25 search with standard SQL filters
SELECT * FROM documents
WHERE content ||| 'search query'
  AND metadata->>'category' === 'tech'
  AND created_at > '2024-01-01'
ORDER BY pdb.score(id) DESC
LIMIT 10;
```

## JOINs

ParadeDB supports all PostgreSQL JOINs:

```sql
SELECT d.content, c.name AS category_name, pdb.score(d.id)
FROM documents d
JOIN categories c ON d.category_id = c.id
WHERE d.content ||| 'search query'
ORDER BY pdb.score(d.id) DESC;

-- Combined scores across tables
SELECT d.content, c.name, pdb.score(d.id) + pdb.score(c.id) AS combined_score
FROM documents d
JOIN categories c ON d.category_id = c.id
WHERE d.content ||| 'query' AND c.name ||| 'query'
ORDER BY combined_score DESC;
```

## Important Considerations

### Community vs Enterprise

| Feature | Community | Enterprise |
|---------|-----------|------------|
| Core search | Yes | Yes |
| ACID | Yes | Yes |
| WAL durability | No | Yes |
| Physical replication | No | Yes |
| High availability | No | Yes |

**Community** is suitable for:
- Development and testing
- Non-critical workloads
- Logical replica setups

**Enterprise** is required for:
- Production with durability requirements
- High availability setups
- Physical replication

### Limitations

- **One BM25 index per table** - it's a covering index, include all needed columns
- **DDL not replicated** - if using logical replication, apply schema changes manually
- **Key field required** - must have unique identifier column

### Index Rebuild

Adding/removing columns requires REINDEX:

```sql
-- Rebuild index after schema change
REINDEX INDEX search_idx;
```

## External Links

- [ParadeDB Documentation](https://docs.paradedb.com)
- [ParadeDB llms.txt](https://docs.paradedb.com/llms.txt) - AI-friendly docs index
- [GitHub Repository](https://github.com/paradedb/paradedb)
- [Quickstart Guide](https://docs.paradedb.com/documentation/getting-started/quickstart)
