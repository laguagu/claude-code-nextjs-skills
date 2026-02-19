# Fuzzy Search & Text Matching Guide

PostgreSQL native fuzzy search without external extensions (except built-in ones).

## pg_trgm (Trigram Similarity)

The most important extension for fuzzy/typo-tolerant search. Built into PostgreSQL.

### Setup

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### How Trigrams Work

Text is split into 3-character sequences:

```
"hello" → {"  h", " he", "hel", "ell", "llo", "lo "}
```

Two strings are compared by the overlap of their trigram sets.

### Operators

| Operator | Function | Description |
|----------|----------|-------------|
| `%` | `similarity()` | Trigram similarity (0-1) |
| `<%` | `word_similarity()` | Word-level similarity |
| `<<%` | `strict_word_similarity()` | Strict word similarity |

```sql
-- Basic similarity (default threshold 0.3)
SELECT * FROM documents WHERE title % 'PostgreSQL';

-- With explicit threshold
SELECT * FROM documents
WHERE similarity(title, 'PostgreSQL') > 0.4
ORDER BY similarity(title, 'PostgreSQL') DESC;

-- Word similarity (better for partial matches)
SELECT * FROM documents
WHERE 'database' <% title
ORDER BY word_similarity('database', title) DESC;
```

### Threshold Tuning

```sql
-- Set global similarity threshold (default 0.3)
SET pg_trgm.similarity_threshold = 0.3;

-- Lower = more results, more typo tolerance
SET pg_trgm.similarity_threshold = 0.1;

-- Higher = fewer results, more precise
SET pg_trgm.similarity_threshold = 0.5;
```

**Recommended thresholds:**

| Use Case | Threshold |
|----------|-----------|
| Autocomplete | 0.1 - 0.2 |
| Fuzzy search | 0.3 (default) |
| Precise matching | 0.5 - 0.6 |
| Near-exact | 0.8+ |

### Indexes for pg_trgm

```sql
-- GIN index (recommended for most cases)
CREATE INDEX ON documents USING gin (title gin_trgm_ops);
CREATE INDEX ON documents USING gin (content gin_trgm_ops);

-- GiST index (supports ORDER BY similarity, KNN)
CREATE INDEX ON documents USING gist (title gist_trgm_ops);
```

**GIN vs GiST for trigrams:**

| Feature | GIN | GiST |
|---------|-----|------|
| `%` operator | Fast | Fast |
| `LIKE`/`ILIKE` | Fast | Fast |
| `ORDER BY similarity()` | Needs sort | Native KNN |
| Index size | Larger | Smaller |
| Build time | Slower | Faster |
| Best for | Filtering (`WHERE`) | Ranking (`ORDER BY`) |

## LIKE / ILIKE Optimization

pg_trgm indexes accelerate LIKE and ILIKE queries automatically:

```sql
-- These use the GIN trigram index (no seq scan!)
SELECT * FROM documents WHERE title ILIKE '%postgres%';
SELECT * FROM documents WHERE content LIKE '%search%';

-- Prefix search (also uses B-tree with text_pattern_ops)
SELECT * FROM documents WHERE title LIKE 'Post%';
```

**Without pg_trgm:** `ILIKE '%term%'` requires a sequential scan.
**With pg_trgm GIN index:** Uses index scan, dramatically faster on large tables.

## fuzzystrmatch Extension

For phonetic and edit-distance matching:

```sql
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- Levenshtein distance (edit distance)
SELECT * FROM documents
WHERE levenshtein(title, 'PostgreSQL') <= 2
ORDER BY levenshtein(title, 'PostgreSQL');

-- Soundex (English phonetic)
SELECT * FROM documents WHERE soundex(title) = soundex('Postgres');

-- Metaphone (better phonetic matching)
SELECT * FROM documents WHERE metaphone(title, 10) = metaphone('Postgres', 10);
```

**When to use:**

- `levenshtein`: Known max edit distance (e.g., 1-2 typos). No index support — slow on large tables.
- `soundex`/`metaphone`: English names, "sounds like" queries. Can index the result.
- **Prefer pg_trgm** for general fuzzy search — it has index support.

## unaccent Extension

Removes accents for accent-insensitive search:

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Direct usage
SELECT unaccent('café résumé');  -- 'cafe resume'

-- Combined with FTS
SELECT * FROM documents
WHERE to_tsvector('simple', unaccent(content)) @@ plainto_tsquery('simple', unaccent('café'));

-- Index for accent-insensitive search
CREATE INDEX ON documents USING gin (to_tsvector('simple', unaccent(content)));
```

## Autocomplete Patterns

### Prefix + Trigram (Recommended)

```sql
-- Fast autocomplete: prefix match first, then fuzzy fallback
CREATE OR REPLACE FUNCTION autocomplete_search(
    search_prefix TEXT,
    max_results INT DEFAULT 10
)
RETURNS TABLE (id INT, title TEXT, score FLOAT)
LANGUAGE sql STABLE AS $$
    -- Exact prefix matches first, then fuzzy matches
    (
        SELECT id, title, 1.0 AS score
        FROM documents
        WHERE title ILIKE search_prefix || '%'
        ORDER BY title
        LIMIT max_results
    )
    UNION ALL
    (
        SELECT id, title, similarity(title, search_prefix) AS score
        FROM documents
        WHERE title % search_prefix
          AND title NOT ILIKE search_prefix || '%'
        ORDER BY similarity(title, search_prefix) DESC
        LIMIT max_results
    )
    LIMIT max_results;
$$;
```

### Indexes for Autocomplete

```sql
-- B-tree for prefix matches
CREATE INDEX ON documents (title text_pattern_ops);

-- GIN trigram for fuzzy fallback
CREATE INDEX ON documents USING gin (title gin_trgm_ops);
```

## Advanced FTS Patterns

### Prefix Matching for Agglutinative Languages

For Finnish, Turkish, Hungarian, Estonian and other agglutinative languages where `'simple'` config
doesn't stem, use prefix matching (`:*` operator) so "xylitol" matches "xylitolin", "xylitolia", etc.

`websearch_to_tsquery` doesn't support `:*`, so build the tsquery manually:

```sql
-- Convert 'fluoridi ksylitoli' → 'fluoridi:* & ksylitoli:*'
CREATE OR REPLACE FUNCTION prefix_tsquery(p_config regconfig, p_text TEXT)
RETURNS tsquery
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
    v_words TEXT[];
    v_parts TEXT[];
    v_word TEXT;
BEGIN
    -- Quoted phrases → fall back to websearch_to_tsquery (no prefix benefit)
    IF p_text LIKE '%"%' THEN
        RETURN websearch_to_tsquery(p_config, p_text);
    END IF;

    -- Split words, strip tsquery-special chars, add :* prefix operator
    v_words := string_to_array(trim(regexp_replace(p_text, '\s+', ' ', 'g')), ' ');
    v_parts := ARRAY[]::TEXT[];

    FOREACH v_word IN ARRAY v_words LOOP
        v_word := regexp_replace(v_word, '[()!&|<>:?\\''"]', '', 'g');
        IF length(v_word) > 0 THEN
            v_parts := array_append(v_parts, v_word || ':*');
        END IF;
    END LOOP;

    IF array_length(v_parts, 1) IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN to_tsquery(p_config, array_to_string(v_parts, ' & '));
END;
$$;
```

Use with `'simple'` config (no stemming, works with any language):

```sql
-- In hybrid_search, replace websearch_to_tsquery with prefix_tsquery:
v_tsquery := prefix_tsquery('simple', p_query_text);

-- Direct usage
SELECT * FROM documents
WHERE text_search @@ prefix_tsquery('simple', 'ksylitoli fluori')
ORDER BY ts_rank_cd(text_search, prefix_tsquery('simple', 'ksylitoli fluori')) DESC;
```

**Key points:**
- Sanitizes `( ) ? ! & | < > : \ '` to prevent tsquery syntax errors from user input
- Falls back to `websearch_to_tsquery` for quoted phrases (`"exact phrase"`)
- Works with any `'simple'` tsvector column — no schema changes needed
- Combines well with hybrid search (RRF) alongside vector similarity

### Weighted Search (Title vs Content)

```sql
-- Title matches rank higher than content matches
SELECT id, title,
    ts_rank(
        setweight(to_tsvector('simple', title), 'A') ||
        setweight(to_tsvector('simple', content), 'B'),
        query
    ) AS rank
FROM documents, plainto_tsquery('simple', 'search term') query
WHERE (
    setweight(to_tsvector('simple', title), 'A') ||
    setweight(to_tsvector('simple', content), 'B')
) @@ query
ORDER BY rank DESC;
```

### Google-style Query Parsing

```sql
-- websearch_to_tsquery supports AND, OR, NOT, "phrases"
SELECT * FROM documents
WHERE to_tsvector('simple', content)
  @@ websearch_to_tsquery('simple', 'postgres -mysql "full text"');
-- Means: contains "postgres" AND "full text", NOT "mysql"
```

### Phrase Search with Distance

```sql
-- Words within 2 positions of each other
SELECT * FROM documents
WHERE to_tsvector('english', content)
  @@ to_tsquery('english', 'full <2> search');
```

## Decision Tree: Choose Text Search Method

```
What kind of text matching?
├─ Exact substring → LIKE/ILIKE + pg_trgm GIN index
├─ Typo tolerance (fuzzy) → pg_trgm similarity (%)
├─ Autocomplete → Prefix (B-tree) + pg_trgm fallback
├─ Keyword search (stemming) → FTS (tsvector/tsquery)
├─ Ranked keyword search → BM25 (pg_search/ParadeDB)
├─ Meaning-based → Semantic vector search (pgvector)
└─ Combined → Hybrid (vector + keyword + optional fuzzy)
```

## Combining Fuzzy with Semantic Search

For the best user experience, combine pg_trgm with vector search:

```sql
-- Stage 1: Quick fuzzy filter for obvious matches
-- Stage 2: Semantic search for meaning-based results
-- Stage 3: RRF to merge results

WITH fuzzy AS (
    SELECT id, similarity(title, $1) AS score,
           ROW_NUMBER() OVER (ORDER BY similarity(title, $1) DESC) AS rank
    FROM documents
    WHERE title % $1
    LIMIT 20
),
semantic AS (
    SELECT id, 1 - (embedding <=> $2) AS score,
           ROW_NUMBER() OVER (ORDER BY embedding <=> $2) AS rank
    FROM documents
    ORDER BY embedding <=> $2
    LIMIT 20
)
SELECT COALESCE(f.id, s.id) AS id,
    COALESCE(1.0/(60 + f.rank), 0) + COALESCE(1.0/(60 + s.rank), 0) AS rrf_score
FROM fuzzy f
FULL OUTER JOIN semantic s ON f.id = s.id
ORDER BY rrf_score DESC
LIMIT 10;
```
