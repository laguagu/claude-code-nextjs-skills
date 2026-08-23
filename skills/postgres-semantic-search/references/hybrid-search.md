# Hybrid Search Guide

## Contents

- [Why Hybrid Search?](#why-hybrid-search) — and when it loses to pure vector
- [Keyword Search Options](#keyword-search-options) — FTS, query parsers, custom configs, BM25
- [Result Fusion Methods](#result-fusion-methods) — RRF, linear weighting
- [Ready-to-Use Functions](#ready-to-use-functions)
- [Chunk-Based Search (RAG)](#chunk-based-search-rag)
- [Best Practices](#best-practices)
- [Choosing Search Method](#choosing-search-method)
- [ParadeDB (Full-Featured Alternative)](#paradedb-full-featured-alternative)
- [Cross-language RRF fusion pattern](#cross-language-rrf-fusion-pattern)
- [Query expansion: a multi-word synonym is not one term](#query-expansion-a-multi-word-synonym-is-not-one-term)

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
     px_q AS (SELECT prefix_tsquery('simple', $1) AS q)
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
phrase hits. `prefix_tsquery(regconfig, text)` is defined in
[fuzzy-search.md](fuzzy-search.md#prefix-matching-for-agglutinative-languages).

### Option 2: pg_search BM25

Better ranking than ts_rank. Requires `pg_search` extension.

> **pg_search API note:** since pg_search 0.20.0 the v2 operator API is the default (`|||`, `&&&`, `###`, `===`, `pdb.score()`, `pdb.snippet()`). The legacy `@@@` + `paradedb.*` functions still work but are slated for removal — the example below uses the v2 syntax. See [paradedb.md](paradedb.md) for the full operator reference.

```sql
-- Install
CREATE EXTENSION pg_search;

-- Create BM25 index (CALL paradedb.create_bm25 has been removed from pg_search)
CREATE INDEX documents_bm25_idx ON documents
USING bm25 (id, content)
WITH (key_field = 'id');

-- Search (v2 API)
SELECT id, pdb.score(id) AS score
FROM documents
WHERE content ||| 'search terms'
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

Generate the prefix once per chunk at ingest time with the cheapest model in
your provider's current lineup. Anthropic reports up to −49% retrieval errors
with this pattern; similar gains are observed on domain-specific corpora.

Caveats:

- One-time cost, low single-digit dollars per few thousand chunks on a small
  model — price it against the provider's current rates, not this line.
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
7. **Measure hybrid against pure vector** - it does not automatically win

### Hybrid does not automatically beat pure vector

Worth measuring rather than assuming. On a ~54,000-chunk single-language
corpus with 92 graded questions, pure vector search matched or beat hybrid on
every headline metric and was an order of magnitude faster:

| Strategy | Recall@15 | MRR | Median latency |
| --- | ---: | ---: | ---: |
| Vector only | **75.0 %** | **0.557** | **76 ms** |
| Hybrid (RRF, vector weight 3.0) | 73.9 % | 0.519 | 681 ms |
| Hybrid (RRF, balanced weights) | 65.2 % | 0.357 | 702 ms |
| Keyword only (FTS) | 33.7 % | 0.144 | 602 ms |

Two things follow, and they pull in opposite directions:

- **Do not add the keyword arm on faith.** A badly weighted hybrid was 10 pp
  *worse* than vector alone here. If you fuse, weight the vector side and
  verify against a vector-only baseline.
- **Do not delete it on these numbers either.** A needle-in-haystack eval set
  asks "is the expected chunk in the top K", and the keyword arm's job is
  exact identifiers — part numbers, section references, proper nouns, SKUs —
  which such a set rarely contains. That value is real and this metric cannot
  see it. Keep the arm, and judge it on queries that actually need it.

The keyword-only row is the other lesson: in a morphologically rich language
FTS alone is not a viable search. A snowball stemmer reduces an inflected
compound to a stem that a query for its first half no longer reaches, which
is what [prefix matching](fuzzy-search.md#prefix-matching-for-agglutinative-languages)
exists to repair.

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

### Translate to a sentence, not to a keyword list

The tempting shortcut is to ask the model for *search terms* — a comma-
separated list of the salient words — on the reasoning that FTS OR-joins
lexemes anyway and the embedding does not care about grammar. Half of that is
right, and acting on it costs more than it gains.

Measured on the same 92-question set, off-language queries, hybrid, top-15:

| Query handling | Recall@15 | MRR |
| --- | ---: | ---: |
| Native-language query (ceiling) | **73.9 %** | **0.519** |
| Off-language, translated to a *sentence* | 66.3 % | 0.452 |
| Off-language, no translation at all | 62.0 % | 0.408 |
| Off-language, translated to a *keyword list* | 47.8 % | 0.305 |

The keyword-list form did help the arm it was designed for — the keyword
recall rose from 5.4 % to 20.7 % — and sank the pipeline anyway, because a
list of twelve nouns embeds far worse than a sentence. It ended up **14 pp
below doing nothing at all**. Translating to a well-formed question keeps the
keyword gain and loses nothing on the vector side.

Two more things that table says:

- **An off-language query costs about 12 pp** even with a multilingual
  embedding model. Budget for it rather than assuming the model erases the
  difference.
- **Hybrid silently degenerates to pure vector** on an off-language query: a
  single-language FTS index scores near zero, so the fused result is the
  vector ranking with extra latency. Here the off-language hybrid numbers were
  identical to vector-only, to three decimals.

## Query expansion: a multi-word synonym is not one term

Adding the other name for a concept is the standard fix for the one thing a
keyword arm cannot do on its own — two names for one idea share no prefix and
no trigram, so only the embedding connects them. Expanding the keyword text is
what lets a literal match happen at all.

**The trap:** `prefix_tsquery` (and `to_tsquery`, and `websearch_to_tsquery`)
OR-joins terms. A *multi-word* expansion therefore does not enter the query as
one phrase — it enters as one independent match arm per word, and the most
common of those words decides the ranking.

Take a pair like `laptop` ↔ `portable computer`. The expansion hands the
keyword arm `computer` alongside `portable`. In a corpus where `computer`
appears in hundreds of documents and `portable` in one, `computer` *is* the
cover density, and the top of the results fills with documents that are about
computers generally and laptops not at all.

Observed on a ~2,000-segment corpus: the generic half of one such pair matched
47 segments against the specific half's 1, and a single off-topic long document
took six of the top ten results for the query the pair was added to fix.

### Why a corpus-frequency cut does not catch it

If you already drop over-common words from short queries (the usual defence,
an absolute corpus-share floor plus a ratio against the query's rarest term),
note that it will not fire here, for two independent reasons:

1. it runs *before* expansion, so it never sees the added word at all; and
2. the added word is often not common enough in absolute terms — 2 % of a
   corpus is under any sane flooding floor.

That floor is correct for a word the user typed: in a query that genuinely
*is* `portable computer`, `computer` is half of what was asked for. **Nobody
typed the expansion.** A term the search adds on the user's behalf has no
claim to be context, so it has to earn its place on selectivity alone.

### The rule that works

Weigh a phrase's parts **against each other**, not against the query, and drop
any part an order of magnitude commoner than the rest of its own phrase:

```text
for each multi-word expansion phrase:
    parts   = tokens with df > 0                 # unmeasured or absent → keep
    if len(parts) < 2: keep the phrase unchanged
    rarest  = min(df of parts)
    generic = parts where df >= rarest * RATIO   # RATIO ~ 20
    keep    = parts - generic
    if keep is empty: keep the phrase unchanged  # never delete an expansion
```

Comparing against the *query's* rarest term instead looks equivalent and is
not. Take a second pair, `sneakers` ↔ `running shoes`, where both halves of
the phrase are moderately common (say df 21 and 11) but the typed term is
unique (df 1). Against the query's rarest term, `running` is 21× commoner and
gets dropped — taking with it the only literal match that reader could have
got. Inside its own phrase, 21 against 11 is the same order of magnitude and
both halves survive. Same rule, opposite and correct outcome, because the
comparison is local to the phrase.

**Trim the keyword text only.** The second embedding pass keeps the whole
phrase — the head noun is what places it in the right region of vector space,
which is exactly the job the keyword arm cannot use it for.

One consequence worth planning for: this needs a document frequency per
expansion token, which is one extra round trip unless you can fold it into a
count you already fetch. Gate it on *having* a multi-word expansion (rare) and
on the search mode having a keyword arm at all.
