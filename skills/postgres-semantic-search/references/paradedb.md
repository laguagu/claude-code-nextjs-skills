# ParadeDB - Elasticsearch Alternative for PostgreSQL

## Contents

- [Documentation Fetch Policy](#documentation-fetch-policy) — **read first**
- [Why ParadeDB?](#why-paradedb)
- [Installation](#installation) — Docker, Neon, self-hosted
- [ParadeDB Index](#paradedb-index) — formerly the BM25 index; tokenizers, stemmers, JSON fields
- [Search Operators](#search-operators)
- [BM25 Scoring](#bm25-scoring)
- [Highlighting (Snippets)](#highlighting-snippets)
- [Faceted Queries (Aggregations)](#faceted-queries-aggregations)
- [Boolean Queries](#boolean-queries)
- [Fuzzy Search](#fuzzy-search)
- [Hybrid Search (BM25 + pgvector)](#hybrid-search-bm25--pgvector)
- [Filtering with Search](#filtering-with-search)
- [JOINs](#joins)
- [Important Considerations](#important-considerations) — licensing, limitations, rebuilds
- [External Links](#external-links)

## Documentation Fetch Policy

ParadeDB API evolves quickly — the content below is a practical guide but may lag behind. Use the live docs as the authoritative source.

**Fetch rules:**
- On the first ParadeDB question in a session, fetch `https://docs.paradedb.com/llms-full.txt`.
- After a successful fetch, treat that content as cached session context and reuse it for later ParadeDB questions in the same session.
- Do not refetch on every turn when the previously fetched docs are still available and relevant.
- Refresh the docs only when one of these is true:
  - the user asks for a refresh or re-fetch
  - the question depends on very recent/current changes
  - the needed content was not included in the earlier fetch
  - session context appears lost, truncated, or unavailable
  - the earlier fetch failed or looked incomplete

**Network failure rules (mandatory):**
If `llms-full.txt` cannot be fetched due to DNS/network/access errors:
- State clearly that live docs could not be accessed and include the actual error.
- If cached session docs exist from an earlier successful fetch, continue from that cached copy unless the user wants to stop.
- If no cached session docs exist, ask whether to proceed with the local content below or to retry.
- Do not invent or infer doc URLs, page paths, or feature availability.
- Do not present unverified links as real.
- Label any fallback statements as assumptions and keep them minimal.

**Response guidelines:**
- Prefer runnable SQL examples over prose-only answers.
- State ParadeDB/Postgres version assumptions when syntax may differ.
- Say when you are relying on cached session docs versus a fresh fetch if that matters to the answer.
- If behavior is uncertain, call it out explicitly instead of guessing.

---

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

### Docker (bundles Postgres + pgvector + pg_search)

Tags follow `paradedb/paradedb:pg15|pg16|pg17|pg18` and `<version>-pg<N>`;
`latest` tracks the newest Postgres. Pin a `<version>-pg<N>` tag for anything
reproducible.

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

> **Note:** pg_search is deprecated for **new** Neon projects as of 2026-03-19 (existing projects keep working). See https://neon.com/docs/extensions/pg_search.

### Self-hosted Postgres

Prebuilt binaries cover Postgres 15+; other versions build from source.
Since pg_search 0.25.0 the extension depends on pgvector's `vector` type, so
install pgvector first.

```sql
CREATE EXTENSION vector;
CREATE EXTENSION pg_search;
```

## ParadeDB Index

The index is a **covering index** - include all columns you'll search, filter, sort, or aggregate.

**The access method was renamed in 0.25.0.** `paradedb` is the primary name;
`USING bm25` remains supported as a backwards-compatible alias, so existing
DDL keeps working. Write `USING paradedb` in new code — every current doc
example uses it, and error messages name it (`operator class "…" does not
exist for access method "paradedb"`). The rename reflects that the index now
also powers vector search, aggregates, top-K and filtering, not just BM25
scoring.

```sql
-- Basic index
CREATE INDEX search_idx ON documents
USING paradedb (id, content, title, category, metadata)
WITH (key_field='id');

-- With tokenizer + stemmer
CREATE INDEX search_idx ON documents
USING paradedb (
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

| Cast | Use Case |
|------|----------|
| `pdb.unicode_words` | General text — **the default** when no tokenizer is given |
| `pdb.icu` | Mixed-language text |
| `pdb.ngram(min, max)` | Partial matching, typo tolerance |
| `pdb.simple` | Simpler splitting; takes the same token-filter options |
| `pdb.literal` | Whole field as one untokenized token |

Note the cast is `pdb.unicode_words` — there is no bare `pdb.unicode`, even
though the docs page is titled "Unicode".

**`pdb.literal` is not optional in one case**: a text or JSON field used in
`GROUP BY` or `ORDER BY` must be literal-tokenized. It is a poor fit for
`match`/`phrase` queries, so a field you both search and sort on needs two
tokenizers (see *multiple tokenizers per field* in the live docs).

The full list is longer than this table — `whitespace`, `regex`,
`edge_ngrams`, `literal_normalized`, `source_code`, and the CJK tokenizers
`jieba`, `lindera` and `chinese_compatible`. Fetch the docs for their exact
cast names and options rather than guessing.

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
CREATE INDEX ON documents USING paradedb (
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

### Phrase (`###`)

```sql
-- Tokens in order, adjacent
SELECT * FROM documents
WHERE content ### 'vector database'
ORDER BY pdb.score(id) DESC;
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

Compose the v2 operators with ordinary SQL `AND` / `OR` / `NOT` — there is no
separate boolean builder to learn.

```sql
-- must: postgresql; should: vector; must_not: deprecated
SELECT * FROM documents
WHERE content &&& 'postgresql'
  AND NOT (content ||| 'deprecated')
ORDER BY pdb.score(id) DESC;
```

> **Legacy v1 API:** the `@@@` operator with `paradedb.boolean()`,
> `paradedb.match()`, `paradedb.phrase()`, `paradedb.score()` and
> `paradedb.snippet()` predates pg_search 0.20.0, where the v2 operator API
> (`|||`, `&&&`, `###`, `===`, `pdb.*`) became the default. `@@@` still parses,
> but write new code in v2. When you need a v1 construct that has no obvious v2
> form, fetch the live docs rather than guessing — the mapping has changed
> across releases.

## Fuzzy Search

```sql
-- Typo-tolerant search (edit distance 2) via tokenizer cast
-- Works with the |||, &&&, and === operators
SELECT * FROM documents
WHERE content ||| 'postgre'::pdb.fuzzy(2)
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

pg_search stores its Tantivy index inside Postgres pages (block storage), so the
index participates in WAL, the buffer cache, and physical replication in the
open-source Community build — durability is not the dividing line it once was.
ParadeDB positions Enterprise as the "production-hardened" edition (support,
hardening, operational tooling) rather than a fixed feature gate.

**Do not quote a feature split from memory.** The boundary moves between
releases. Fetch `https://docs.paradedb.com/llms-full.txt` or ask ParadeDB
before telling a user a capability is Enterprise-only.

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
- [ParadeDB AI Docs](https://docs.paradedb.com/llms-full.txt) - Full docs for AI agents (always current)
- [ParadeDB MCP Endpoint](https://docs.paradedb.com/mcp) - For MCP-compatible tools
- [GitHub Repository](https://github.com/paradedb/paradedb)
- [Install Guide](https://docs.paradedb.com/documentation/getting-started/install)
