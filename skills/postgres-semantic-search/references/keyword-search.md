# Keyword search: FTS, trigrams and ParadeDB

Read when building or debugging the keyword arm of a hybrid search, when
full-text search returns nothing for words that are visibly there, or when the
corpus is not English. Every failure below returns zero rows or plausible
results, never an error.

## Contents

- [Long questions match nothing](#long-questions-match-nothing)
- [Accents, invisible characters and language configs](#accents-invisible-characters-and-language-configs)
- [A dead keyword arm](#a-dead-keyword-arm)
- [Inflected languages: prefix matching](#inflected-languages-prefix-matching)
- [Stemmer, lemmatizer or neither](#stemmer-lemmatizer-or-neither)
- [Trigrams, typos and autocomplete](#trigrams-typos-and-autocomplete)
- [ParadeDB (pg_search)](#paradedb-pg_search)

## Long questions match nothing

`plainto_tsquery` and `websearch_to_tsquery` both AND every bare term. A
question with nine content words matches only rows containing all nine stems,
which on real prose is none, and the keyword arm of a hybrid silently adds
nothing. English hides this because stop words drop out; in languages whose
questions are mostly content words, such as Finnish, it happens constantly.

For plain input, parse (keeping stemming and stop words), rewrite AND to OR and
let `ts_rank_cd` reward rows that match more terms, closer together:

```sql
CROSS JOIN LATERAL (
  SELECT replace(plainto_tsquery('finnish', $1)::text, ' & ', ' | ')::tsquery AS tsq
) q
WHERE numnode(q.tsq) > 0 AND tsv @@ q.tsq
ORDER BY ts_rank_cd(tsv, q.tsq) DESC
```

If the UI supports quotes, `OR` or `-term`, keep `websearch_to_tsquery`
unchanged: the same rewrite turns `foo -bar` into `foo | !bar`, which matches
almost everything.

## Accents, invisible characters and language configs

- **Fold accents only where they are decorative** (French, Spanish,
  Portuguese, Italian), and do it inside a text search configuration so index
  and query agree:

  ```sql
  CREATE EXTENSION IF NOT EXISTS unaccent;
  CREATE TEXT SEARCH CONFIGURATION french_unaccent (COPY = french);
  ALTER TEXT SEARCH CONFIGURATION french_unaccent
    ALTER MAPPING FOR hword, hword_part, word WITH unaccent, french_stem;
  ```

  Avoid blanket folding for Finnish, Swedish, Danish, Norwegian, German,
  Turkish or Hungarian: marked letters can be distinct letters (`säästää` "to save" becomes
  `saastaa`, "filth" in the partitive), and the stemmer receives forms it was
  not built for.
  Handle accentless typing with a trigram fallback instead.
- **Normalize unwanted zero-width export artifacts** consistently at ingest and
  query time. Do not indiscriminately delete ZWNJ/ZWJ from every language or
  field: they can carry meaningful shaping or text information. Postgres does not treat
  them as whitespace, so the glued token skips stemming:
  `to_tsvector('finnish', 'kirjanpidossa')` gives `kirjanpido`, the same word
  followed by U+200B stays whole and never matches. A CMS export had them in 10
  titles and 23 chunks, invisible in every editor.
- **Mixed or unknown languages**: `'simple'` plus prefix or trigram matching.
  A per-row language works in a generated column or index only if the column
  is of type `regconfig` (`to_tsvector(lang, body)`); casting a text column
  (`lang::regconfig`) is not immutable and is rejected. Otherwise write the
  tsvector at ingest.
- **The index expression must match the query**, config included:
  `to_tsvector('simple', content)` in the index serves only that exact call.

## A dead keyword arm

A stored `GENERATED ALWAYS AS (...)` tsvector column can silently become a
plain column when an ORM regenerates a migration without the expression. Every
row then holds NULL, the keyword arm matches nothing, and hybrid search is
vector search. In one production system this went unnoticed for about six
months because results still came back.

```sql
-- attgenerated 's' = stored generated column; empty = plain column
SELECT attrelid::regclass, attname, attgenerated
FROM pg_attribute WHERE attname = 'tsv' AND NOT attisdropped;
SELECT count(*) AS total, count(tsv) AS populated FROM documents;
```

Repair is `DROP COLUMN` plus `ADD COLUMN ... GENERATED`, which drops its indexes
too. If only the application API is available, compare literal-term keyword-only,
hybrid and vector-only results. Identical hybrid/vector lists are a symptom,
not proof of a dead arm: weak weights, overlapping candidates or an unsuitable
query can also produce them. Inspect population and arm matches when possible.

## Inflected languages: prefix matching

With the `'simple'` config, prefix terms (`kirjasto:*`) match suffixed forms
(`kirjastossa`, `kirjastoon`). Two cases still return nothing:

- **Stem changes.** Finnish inflection rewrites many stems (`-us` to `-ukse-`,
  consonant gradation), so `hakemus:*` misses `hakemuksesta` and `asiakas:*`
  misses `asiakkaan`. Any one
  term can miss, so AND-joining terms returned zero rows for every multi-word
  query on a ~2,000-document Finnish corpus. OR-join them and let `ts_rank_cd`
  order the pool.
- **Hyphenated tokens.** `to_tsquery('simple', 'verkko-opetus:*')` becomes a
  phrase, `'verkko-opetus':* <-> 'verkko':* <-> 'opetus':*`, that does not match
  `verkko-opetuksesta`. Expand the token into an OR of the compound and its
  parts.

[scripts/prefix_tsquery.sql](../scripts/prefix_tsquery.sql) does both and
sanitizes raw input. To combine it with a stemmed config, run both queries and
take the higher rank, damping the prefix side (for example × 0.7) so exact
matches win ties.

Keyword search alone is weak in these languages: a stemmer reduces a compound
to a stem that a query for its first half no longer reaches. On one corpus FTS
alone reached 33.7 % Recall@15 against 75.0 % for vector search.

## Stemmer, lemmatizer or neither

Measured on a Finnish lecture-transcript corpus (~2,000 segments, 67 long
questions, 15 short terms, the same 15 typed inflected), keyword arm alone and
fused with vector search as the app does (right moment first):

| Keyword arm | Long, alone | Long, hybrid | Inflected terms, alone | Inflected terms, hybrid |
| --- | ---: | ---: | ---: | ---: |
| `simple` + prefix (baseline) | 12 | 37 | 4 | 12 |
| Postgres `finnish` stemmer, OR | 21 | 35 | 9 | 12 |
| Dictionary lemmas (Voikko), OR | 17 | 35 | 6 | 11 |
| Lemmas, stemmer for unknown words | 17 | 39 | 10 | 12 |
| No keyword arm | – | 37 | – | 12 |

- **Embeddings already absorb inflection.** Vector search alone found 8 of the
  15 terms in base form and 9 inflected. The prefix arm fell from 9 to 4 and
  matched nothing for 5 inflected terms: a prefix reaches suffixed forms of the
  typed word, never the base form of an inflected query (`purentakiskon:*`
  misses `purentakisko`).
- **Morphology helps the keyword arm alone, not hybrid.** The stemmer won 11
  and lost 2 long questions alone (sign test p = 0.02). Fused, the stemmer and
  lemma variants stayed within two queries of the baseline, which itself tied
  "no keyword arm", and none of the differences was significant. Add
  a stemmed arm for keyword-only search or highlighted literal matches; for a
  hybrid ranking, measure before paying for it.
- **Prefer the stemmer to a dictionary lemmatizer** for spoken or domain text.
  Voikko could not analyse 8.3 % of the running words (a quarter of distinct
  words): spoken forms (`mä`, `tota`) and domain terms (`uniapnea`, `tmd`). A
  lemmatizer that keeps unknown words as typed never joins `pulpiitista` with
  `pulpiitti`; stem them instead. The snowball stemmer needs no dictionary and
  no service beside Postgres.
- **Compound splitting floods the arm.** Indexing compound parts made a long
  question match a median of 1,056 of 2,072 segments (221 for the prefix
  baseline) and scored 4 fewer long questions in hybrid. Leave it off unless
  queries name compound halves.
- **A library's default query mode can switch the arm off.** A lemmatizing
  store that defaulted to `websearch_to_tsquery` (AND) matched nothing for all
  67 long questions. Check the default, not the README's recommended mode.

With 15 short terms, only a gap of about 5 queries is significant; the long
set was model-labelled. One corpus, so re-measure on yours.

## Trigrams, typos and autocomplete

- `%` compares whole strings: `similarity('pos', 'PostgreSQL full text search')`
  is 0.10, far below the 0.3 default threshold. `<%` (`word_similarity`) compares
  with the best-matching words and gives 0.75. Use `<%` for prefixes and for
  short queries against long text.
- A trigram GIN index (`gin_trgm_ops`) serves `%`, `<%`, `LIKE` and `ILIKE`, with
  parameters too. A `text_pattern_ops` B-tree serves only left-anchored,
  case-sensitive `LIKE` with a pattern known at plan time. GiST (`gist_trgm_ops`) adds
  `ORDER BY col <-> 'text'` nearest-neighbour ordering.
- Escape `%`, `_` and `\` in user input before building a `LIKE` pattern.
- Trigrams also catch compound-word partials (`ammattikorkea` →
  `ammattikorkeakoulu`) that stemmed FTS misses.

## ParadeDB (pg_search)

ParadeDB's API changes between releases. For query syntax, use the official
ParadeDB agent skill ([paradedb/agent-skills](https://github.com/paradedb/agent-skills))
if it is installed, or fetch the docs index at
`https://www.paradedb.com/docs/llms.txt`. Points that are easy to get wrong
from memory (checked 2026-09):

- The index is `CREATE INDEX ... USING paradedb (...) WITH (key_field = 'id')`
  since 0.25.0; `USING bm25` is a backwards-compatible alias, and
  `CALL paradedb.create_bm25` is gone. The key field is unique and listed first.
- One ParadeDB index per table, covering every column you search, filter, sort
  or aggregate on. Adding or removing a field, or changing its tokenizer, means
  rebuilding it (the docs build a new one `CONCURRENTLY`, then drop the old).
- Current query API: `|||` (any term), `&&&` (all terms), `###` (phrase), `===`
  (exact), `pdb.score()`, `pdb.snippet()`. The `paradedb.*` builder functions are
  legacy.
- Tokenizer and stemmer are casts in the index definition:
  `(content::pdb.unicode_words('stemmer=finnish'))`. The cast is
  `pdb.unicode_words`, not `pdb.unicode`; the untokenized one is `pdb.literal`,
  not `raw`; JSON tokenizer objects are the pre-v2 syntax.
- A text field used as a Top K sort key or in an aggregate must use
  `pdb.literal` or `pdb.literal_normalized`, which are poor for text matching;
  index such a field twice with different tokenizers.
- pg_search 0.25+ needs pgvector installed first. A vector column inside the
  ParadeDB index is searched by ParadeDB, not by pgvector's HNSW.
- Hosting varies: Neon removed pg_search (its BM25 option is `lakebase_text`).
  Do not quote which features are Enterprise-only from memory; the boundary
  moves.
