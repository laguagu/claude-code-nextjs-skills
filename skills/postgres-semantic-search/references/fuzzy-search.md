# Fuzzy Search & Text Matching Guide

PostgreSQL native fuzzy search without external extensions (except built-in ones).

## Contents

- [pg_trgm (Trigram Similarity)](#pg_trgm-trigram-similarity)
- [LIKE / ILIKE Optimization](#like--ilike-optimization)
- [fuzzystrmatch Extension](#fuzzystrmatch-extension)
- [unaccent Extension](#unaccent-extension)
- [Autocomplete Patterns](#autocomplete-patterns)
- [Advanced FTS Patterns](#advanced-fts-patterns)
- [Decision Tree: Choose Text Search Method](#decision-tree-choose-text-search-method)
- [Combining Fuzzy with Semantic Search](#combining-fuzzy-with-semantic-search)

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
        WHERE lower(title) LIKE lower(search_prefix) || '%'
        ORDER BY title
        LIMIT max_results
    )
    UNION ALL
    (
        SELECT id, title, word_similarity(search_prefix, title) AS score
        FROM documents
        WHERE search_prefix <% title
          AND lower(title) NOT LIKE lower(search_prefix) || '%'
        ORDER BY word_similarity(search_prefix, title) DESC
        LIMIT max_results
    )
    LIMIT max_results;
$$;
```

Two details that break naive versions of this:

- **`ILIKE` cannot use a `text_pattern_ops` B-tree.** Match on
  `lower(title) LIKE lower(prefix) || '%'` and index the same expression, or the
  prefix branch falls back to a sequential scan.
- **`%` (`similarity`) is the wrong operator for a prefix.** A 3-character
  prefix shares few trigrams with a long title, so `title % 'pos'` scores near
  zero. `<%` (`word_similarity`) compares the prefix against the best-matching
  word instead.

### Indexes for Autocomplete

```sql
-- B-tree on the same expression the query uses, for the prefix branch
CREATE INDEX ON documents (lower(title) text_pattern_ops);

-- GIN trigram for the fuzzy fallback (also serves <% and ILIKE '%x%')
CREATE INDEX ON documents USING gin (title gin_trgm_ops);
```

## Advanced FTS Patterns

### Prefix Matching for Agglutinative Languages

For Finnish, Turkish, Hungarian, Estonian and other agglutinative languages
where `'simple'` does no stemming, prefix matching (`:*`) lets one query form
match inflected ones. `websearch_to_tsquery` cannot emit `:*`, so the tsquery
has to be built by hand.

Prefix matching only carries you so far, and the two places it breaks both
return **zero rows** rather than erroring. Every claim below is a statement
Postgres will confirm — paste them into `psql`.

**Prefix matching survives plain suffixation:**

```sql
SELECT to_tsvector('simple','kirjastossa') @@ to_tsquery('simple','kirjasto:*');  -- true
SELECT to_tsvector('simple','kirjastoon')  @@ to_tsquery('simple','kirjasto:*');  -- true
```

**It does not survive stem changes.** Finnish consonant gradation rewrites the
stem, so the prefix stops being a prefix:

```sql
SELECT to_tsvector('simple','hakemuksesta') @@ to_tsquery('simple','hakemus:*'); -- false
SELECT to_tsvector('simple','asiakkaan')    @@ to_tsquery('simple','asiakas:*'); -- false
```

**1. Do not AND the terms together.** Because any single term can miss like
that, requiring all of them multiplies the risk until a realistic multi-word
query matches nothing at all. On a ~2,000-document Finnish corpus, AND-joining
returned zero rows for every multi-word query tried, while OR-joining returned
usable candidate pools for the same queries.

OR-join and let `ts_rank_cd` order the pool: cover density ranks a document
matching four query terms far above one matching a single filler word. When
this feeds RRF, only the top slice survives anyway, so the extra recall does not
become precision loss downstream.

**2. A hyphenated token becomes a phrase query.** Postgres' parser splits it and
`to_tsquery` joins the parts with `<->`:

```sql
SELECT to_tsquery('simple','verkko-opetus:*');
-- 'verkko-opetus':* <-> 'verkko':* <-> 'opetus':*

SELECT to_tsvector('simple','verkko-opetuksesta')
       @@ to_tsquery('simple','verkko-opetus:*');                    -- false

-- An explicit OR of the compound and its parts does match:
SELECT to_tsvector('simple','verkko-opetuksesta')
       @@ to_tsquery('simple','''verkko-opetus'':* | ''verkko'':* | ''opetus'':*');  -- true
```

Quoting the token does not help; the parser splits it regardless. Expand
hyphenated tokens into that OR group instead.

```sql
-- 'verkko-opetus kirjasto'
--   → ('verkko-opetus':* | 'verkko':* | 'opetus':*) | 'kirjasto':*
CREATE OR REPLACE FUNCTION prefix_tsquery(
    p_config regconfig,
    p_text   TEXT,
    p_join   TEXT              -- 'auto' | 'or' | 'and'; 'and' is for ablations
)
RETURNS tsquery
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
    -- Tokens this short are function words that match nearly every document.
    -- Dropped from OR queries — but only when a longer one survives, so a
    -- genuinely short query ("EU", "ISO") still works on its own.
    MIN_OR_TERM_LENGTH CONSTANT INT := 3;
    v_token   TEXT;
    v_cleaned TEXT;
    v_parts   TEXT[];
    v_arms    TEXT[];
    v_terms   TEXT[] := ARRAY[]::TEXT[];
    v_weights INT[]  := ARRAY[]::INT[];
    v_kept    TEXT[];
    v_join    TEXT;
BEGIN
    -- An explicit phrase is what websearch_to_tsquery is for.
    IF p_text LIKE '%"%' THEN
        RETURN websearch_to_tsquery(p_config, p_text);
    END IF;

    FOREACH v_token IN ARRAY regexp_split_to_array(trim(p_text), '\s+') LOOP
        -- Strip tsquery operators, then leading/trailing punctuation. Without
        -- this, input containing & | ! ( ) : raises a syntax error.
        v_cleaned := regexp_replace(v_token, '[''"()!&|<>:?\\*]', '', 'g');
        v_cleaned := regexp_replace(
            v_cleaned, '^[^[:alnum:]]+|[^[:alnum:]]+$', '', 'g');
        CONTINUE WHEN v_cleaned = '';

        v_parts := ARRAY(
            SELECT p
            FROM regexp_split_to_table(v_cleaned, '[^[:alnum:]]+') AS p
            WHERE p <> ''
        );
        CONTINUE WHEN array_length(v_parts, 1) IS NULL;

        IF array_length(v_parts, 1) = 1 THEN
            v_arms := v_parts;
        ELSE
            -- Compound first (most specific), then each part, first-seen order.
            v_arms := ARRAY(
                SELECT a
                FROM (
                    SELECT u.a, min(u.ord) AS ord
                    FROM unnest(ARRAY[v_cleaned] || v_parts)
                         WITH ORDINALITY AS u(a, ord)
                    GROUP BY u.a
                ) s
                ORDER BY s.ord
            );
        END IF;

        IF array_length(v_arms, 1) = 1 THEN
            v_terms := v_terms || (quote_literal(v_arms[1]) || ':*');
        ELSE
            v_terms := v_terms || (
                '(' || array_to_string(
                    ARRAY(SELECT quote_literal(a) || ':*' FROM unnest(v_arms) AS a),
                    ' | ') || ')'
            );
        END IF;

        v_weights := v_weights || (
            SELECT max(length(a))::INT FROM unnest(v_arms) AS a
        );
    END LOOP;

    IF array_length(v_terms, 1) IS NULL THEN
        RETURN NULL;
    END IF;

    -- A single term is unambiguous; the join mode never applies to it.
    IF array_length(v_terms, 1) = 1 THEN
        v_join := 'and';
    ELSIF p_join = 'auto' THEN
        v_join := 'or';
    ELSE
        v_join := p_join;
    END IF;

    IF v_join = 'or' THEN
        v_kept := ARRAY(
            SELECT u.t FROM unnest(v_terms, v_weights) AS u(t, w)
            WHERE u.w >= MIN_OR_TERM_LENGTH
        );
        IF array_length(v_kept, 1) IS NULL THEN
            v_kept := v_terms;   -- an all-short query still has to work
        END IF;
    ELSE
        v_kept := v_terms;
    END IF;

    RETURN to_tsquery(
        p_config,
        array_to_string(v_kept, CASE WHEN v_join = 'or' THEN ' | ' ELSE ' & ' END)
    );
END;
$$;
```

Add a two-argument wrapper so existing call sites keep working:

```sql
CREATE OR REPLACE FUNCTION prefix_tsquery(p_config regconfig, p_text TEXT)
RETURNS tsquery LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT prefix_tsquery(p_config, p_text, 'auto') $$;
```

> [!IMPORTANT]
> Use a wrapper, **not** `DEFAULT 'auto'` on the third parameter. With a default,
> a database that already has the two-argument version gets two candidates for
> `prefix_tsquery('simple', $1)` and every existing call fails with
> `function prefix_tsquery(unknown, unknown) is not unique`. That is the exact
> situation when upgrading, which is when it hurts most.

Keep the join mode as an argument. Which of OR and AND wins is corpus-dependent,
and having it as a parameter turns that question into a one-line ablation
instead of a migration.

Use with `'simple'` config (no stemming, works with any language):

```sql
-- In hybrid_search, replace websearch_to_tsquery with prefix_tsquery:
v_tsquery := prefix_tsquery('simple', p_query_text);

-- Direct usage
SELECT * FROM documents
WHERE text_search @@ prefix_tsquery('simple', 'kirjasto opetus')
ORDER BY ts_rank_cd(text_search, prefix_tsquery('simple', 'kirjasto opetus')) DESC;
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
