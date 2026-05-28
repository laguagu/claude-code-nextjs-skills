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
WHERE to_tsvector('simple', content) @@ websearch_to_tsquery('simple', 'search terms')
ORDER BY ts_rank(to_tsvector('simple', content), websearch_to_tsquery('simple', 'search terms')) DESC;
```

**Language options:**
- `'simple'`: No stemming, basic tokenization. Good for mixed languages.
- `'english'`: English stemming. "running" matches "run".
- `'finnish'`, `'german'`, `'french'`, etc.: Built-in stemmers.

### Query parsers: `websearch_to_tsquery` vs `plainto_tsquery`

This is the most common FTS pitfall. Pick the right parser for your input:

| Parser | Combines terms with | Best for |
|--------|--------------------|---------|
| `plainto_tsquery` | AND (`&`) | Short, exact-match queries (1-3 keywords) |
| `websearch_to_tsquery` | Smart: spaces = AND, `OR` = OR, `"quoted"` = phrase | Natural-language questions, search-engine-style input |
| `phraseto_tsquery` | Phrase (`<->`) | When token order matters |
| `to_tsquery` | Manual operators | Power users only — fragile with raw input |

**The trap:** `plainto_tsquery('how do I reset my password')` requires ALL six
words to be present in a single document → returns 0 hits for most realistic
queries. Use `websearch_to_tsquery` for any user-typed input.

```sql
-- ❌ BAD: long natural-language query → 0 hits
WHERE tsv @@ plainto_tsquery('english', 'how do I reset my password')

-- ✅ GOOD: same query, OR-friendly matching
WHERE tsv @@ websearch_to_tsquery('english', 'how do I reset my password')
```

### Custom FTS configuration (e.g., language + unaccent)

For non-English content, combine a stemmer with `unaccent` so accented
characters match their base forms ("café" matches "cafe", "naïve" matches
"naive"). This is essential for Finnish, French, German, Spanish, Portuguese,
etc.

```sql
-- 1. Enable unaccent extension
CREATE EXTENSION IF NOT EXISTS unaccent;

-- 2. Create custom config: copy the language base, then prepend unaccent mapping
CREATE TEXT SEARCH CONFIGURATION finnish_unaccent (COPY = finnish);
ALTER TEXT SEARCH CONFIGURATION finnish_unaccent
  ALTER MAPPING FOR hword, hword_part, word
  WITH unaccent, finnish_stem;

-- 3. Use in indexes and queries
CREATE INDEX ON documents USING GIN (to_tsvector('finnish_unaccent', content));

SELECT * FROM documents
WHERE to_tsvector('finnish_unaccent', content) @@ websearch_to_tsquery('finnish_unaccent', 'kahvi naiivi');
-- Matches both "kahvi"/"kahvia" and "naïvi"/"naiivit"
```

The same pattern works for any language: `german_unaccent`, `spanish_unaccent`,
etc. Always create the custom config once (DDL), then reference it everywhere.

### Dual FTS (exact + prefix) for agglutinative languages

`websearch_to_tsquery` handles OR / quoted phrases well but still misses
inflected forms (`vuosiloma` → `vuosilomaa`). `plainto_tsquery` fails
differently — ANDs every token, returning 0 hits on 15-word natural questions.
For Finnish, Turkish, Hungarian, Estonian and similar, run both queries and
take the max rank, damping the fuzzier source so exact matches keep winning
ties:

```sql
WITH ws_q AS (SELECT websearch_to_tsquery('finnish_unaccent', $1) AS q),
     px_q AS (SELECT prefix_tsquery($1) AS q)
SELECT id,
       GREATEST(
         COALESCE(ts_rank_cd(tsv, (SELECT q FROM ws_q)), 0),
         COALESCE(ts_rank_cd(tsv, (SELECT q FROM px_q)), 0) * 0.7
       ) AS fts_score
FROM documents
WHERE tsv @@ (SELECT q FROM ws_q) OR tsv @@ (SELECT q FROM px_q)
ORDER BY fts_score DESC LIMIT 30;
```

This boosts recall without over-ranking fuzzy prefix matches against exact
phrase hits. See `prefix_tsquery` definition in the main SKILL.md.

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

### Contextual chunk embeddings

Chunk text alone often lacks disambiguating context ("section 28 says…" — of
which document?). Before embedding, prepend a short prefix describing the
chunk's location in the parent document:

```
embed_input = `${document_title}, §${section_number} ${section_title}\n\n${chunk_text}`
```

Generate the prefix once per chunk with a cheap LLM at ingest time
(GPT-4o-mini, Claude Haiku). Anthropic reports up to −49% retrieval errors
with this pattern; similar gains are observed on domain-specific corpora.

Caveats:

- One-time cost, typically ~$1–5 per 5k chunks with a mini model.
- Re-generate the prefix if chunking strategy changes.
- Do **not** include the prefix in the FTS `tsv` column — it inflates false
  positives on common document-title keywords. Embed with context, index
  FTS on raw chunk text.

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

## Cross-language RRF fusion pattern

When the corpus is one language and queries arrive in many, a single hybrid
pass underperforms on off-language queries: multilingual embeddings collapse
domain-specific terms (jargon, proper nouns, compound words) onto distant
points in cross-lingual space. Two-pass RRF recovers them without changing
the index.

```text
query_lang != corpus_lang ?
    pass_1 = hybrid_search(translated_text, embedding=embed(query_original))
    pass_2 = hybrid_search(translated_text, embedding=embed(translated_text))
    results = rrf_merge([pass_1, pass_2], k=60)
else:
    results = hybrid_search(query_text, embedding=embed(query_text))
```

Both passes use the same translated FTS text. Pass 1 leans on the model's
cross-lingual map; pass 2 anchors in native-language embedding space and
recovers the domain terms pass 1 missed. RRF (k=60) fuses by rank, so the
two passes' score scales don't have to align.

Cache the translation and both embeddings — keyed by normalized query +
model + target language. Gate fusion behind a language-detection check so
already-corpus-language queries take the single-pass path.
