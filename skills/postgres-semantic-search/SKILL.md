---
name: postgres-semantic-search
description: >-
  Builds and tunes PostgreSQL retrieval with pgvector, full-text search,
  pg_trgm, hybrid fusion, ParadeDB BM25 and reranking. Use for search/RAG
  implementation, weak results, filtered ANN scans, non-English corpora or
  retrieval evaluation. For general schema, RLS and query tuning unrelated
  to retrieval, use supabase-postgres-best-practices.
---

# PostgreSQL Semantic Search

Decisions, measured findings and silent failure modes for search built on
Postgres, plus tested SQL building blocks in [scripts/](#scripts). Syntax the
official docs cover well is left to them; what is here goes wrong without an
error.

## Build order

1. Look at what users actually type: identifiers and codes, one-to-three-word
   terms, full questions, which languages. That decides which arms you need.
2. Start with the simplest retrieval suited to those queries: exact/keyword
   lookup or vector search. For approximate vector search, keep exact vector
   search as the recall baseline.
3. Build two eval sets, long questions and short terms, before tuning
   ([evaluation.md](references/evaluation.md)).
4. Add another arm and fuse with RRF only where it improves the baseline on
   the queries that need it ([hybrid-search.md](references/hybrid-search.md)).
5. Add a reranker last, over the head of a good shortlist
   ([reranking.md](references/reranking.md)).

Change one thing at a time. Predefine the acceptance rule, measure run-to-run
spread and inspect wins/losses for the query populations the change affects.
The numerical findings below are corpus-specific observations, not universal
performance guarantees.

## Choosing

- **Column type by dimensions**, not provider: `vector(N)` indexes up to 2,000;
  up to 4,000 index a `halfvec` cast (or use a `halfvec` column); above that,
  binary quantization or Matryoshka truncation.
- **HNSW by default**, IVFFlat when memory or build time rules HNSW out. No row
  count decides it: measure recall and latency against exact search.
- **Models change every few months.** Pick embedding and reranker models from
  the provider's current docs, prefer multilingual models for non-English text,
  and evaluate on the target language before committing.
- **Hybrid when users type both questions and terms.** On a Finnish corpus
  keyword alone was weak on long questions (24 % right first), vector alone on
  short terms (53 %), and hybrid led on both (53 % and 93 %;
  [hybrid-search.md](references/hybrid-search.md#where-each-arm-fails-long-questions-and-short-terms)).
- **BM25 is not available everywhere**: managed hosts differ (Neon removed
  `pg_search`). Plain FTS with the fixes below is often enough.

## Silent failures

These return fewer rows, zero rows or plausible results, never an error.

pgvector ([pgvector.md](references/pgvector.md)):

- **Without iterative scanning, HNSW results are limited by `hnsw.ef_search`** (default 40). A larger
  `LIMIT`, or a selective `WHERE`, silently returns fewer. Enable
  `hnsw.iterative_scan` (off by default), or use partial indexes or partitions.
- **The default `ef_search` can cost recall** with no warning. Raise it until
  recall against exact search stops moving. If `EXPLAIN` shows a seq scan,
  tuning does nothing, and the seq scan may be the faster plan.
- **A distance threshold goes outside a `MATERIALIZED` CTE**, other filters
  inside it.
- **`SET` is per connection.** Behind a transaction pooler use `SET LOCAL` in the
  same transaction, or a function-level `SET`.
- **Similarity cutoffs are model-specific**: a cutoff tuned for one model
  returns nothing for another. `1 - (a <#> b)` is not cosine similarity.
- **Clients mangle JS arrays**: node-postgres sends `{0.1,0.2}` and Drizzle's
  `sql` template expands an array into `($1, $2, ...)`; vector input rejects
  both. Send `JSON.stringify(embedding)` and cast with `::vector`.

Keyword ([keyword-search.md](references/keyword-search.md)):

- **`plainto_tsquery` and unquoted plain input to `websearch_to_tsquery`
  AND bare terms**, so long questions can match nothing. For plain-input
  retrieval, consider OR and `ts_rank_cd`; preserve explicit web-search
  quotes, OR and exclusions.
- **`unaccent` merges distinct words** in Finnish, Swedish, German or Turkish.
  Fold only decorative accents, inside a text search configuration.
- **Unwanted zero-width export artifacts** can glue onto tokens and block
  stemming. Normalize them consistently without deleting meaningful ZWNJ/ZWJ.
- **A generated tsvector column can silently become a plain NULL column** after
  an ORM migration. If hybrid and vector-only return identical lists, the
  keyword arm may be absent or ineffective: check NULL/population counts and
  keyword-only results before diagnosing it.
- **Prefix matching in inflected languages** must OR-join terms and expand
  hyphenated tokens ([prefix_tsquery.sql](scripts/prefix_tsquery.sql)).
- **`%` compares whole strings**; use `<%` for prefixes and short queries
  against long text.

## Non-English and chunking

- **Cap chunks with the selected embedding model's tokenizer and input limit.**
  Character-to-token ratios vary by model, language and text. An English-derived
  character cap can overflow other-language input and fail the whole batch.
- **Off-language queries** can make the lexical arm ineffective. Evaluate
  sentence translation and two-pass fusion against untranslated queries; a
  keyword-list translation regressed one measured corpus.
- **A multi-word synonym expansion** enters the tsquery as independent words,
  and its generic word takes over the ranking. Trim parts an order of
  magnitude commoner than the rest of their own phrase.
- **Inflection**: compare model and lexical behavior on actual inflected queries.
  One Finnish corpus benefited from stemming in keyword-only search, with no
  significant hybrid gain; dictionary coverage and compound expansion need
  measurement on the target text.
  Prefix matching never reaches the base form of an inflected query
  ([keyword-search.md](references/keyword-search.md#stemmer-lemmatizer-or-neither)).
- **Transcripts**: chunk length barely changed which video was found. A second,
  fine-grained search over the subtitle cues inside the matched segment finds
  the moment.

Details and measurements: [hybrid-search.md](references/hybrid-search.md).

## Reranking

- **Evaluate rerank depth on short terms and full questions.** On one Finnish
  transcript corpus, shallow reranking preserved topical-term results better
  than reordering all 30. Compare no reranking and several depths; that result
  does not establish a universal top-5 rule or cross-encoder behavior.
- **The relevance question's wording can matter more than the model** (about
  thirty points on one corpus). Every criterion must be checkable from the text
  sent, and the source title belongs in the reranker input.
- **Choose by the deployment/data policy and measured latency.** Model size,
  quantization, batching and hardware affect CPU/GPU suitability; do not infer
  a universal latency cutoff from parameter count. Hosted reranking sends
  candidate text to that provider. Define a timeout fallback.
- **Measure the shortlist ceiling first**: a reranker cannot recover what the
  first stage missed.
- Make the backend/depth configurable when operationally useful; choose the
  enabled default from the accepted quality and latency results. If callers may choose a
  backend per request, allow only admin-enabled ones.

Numbers, model trade-offs and adoption rules: [reranking.md](references/reranking.md)
and [jev-rerank-bench](https://github.com/laguagu/jev-rerank-bench).

## Scripts

For a new sample database, use `setup.sql`, then `indexes.sql` and selected
function files. For an existing database, review/adapt them as migrations: they
assume `documents(id, title, content, metadata, embedding vector(1536))` and
`chunks(id, document_id, chunk_index, content, embedding)`: change the names
and dimension in every file together. Some function files drop older signatures;
review dependent objects before applying them. These are building blocks, not a
complete production migration/authorization policy. None sets `hnsw.ef_search`;
the caller does.

| File | Functions (real parameter names) |
| --- | --- |
| [semantic_search.sql](scripts/semantic_search.sql) | `match_documents(query_embedding, match_threshold, match_count)`, `match_documents_filtered(query_embedding, filter_metadata, match_threshold, match_count)`, `match_chunks(query_embedding, match_threshold, match_count)`; `match_threshold` NULL = plain top-k |
| [hybrid_search_fts.sql](scripts/hybrid_search_fts.sql) | `hybrid_search_fts(query_embedding, query_text, match_count, rrf_k, fts_language, vector_weight, keyword_weight)`; either input may be NULL |
| [hybrid_search_bm25.sql](scripts/hybrid_search_bm25.sql) | `hybrid_search_bm25(...)`, `hybrid_search_chunks_bm25(...)`: same parameters without `fts_language`; needs `pg_search` |
| [fuzzy_search.sql](scripts/fuzzy_search.sql) | `fuzzy_search_trigram(query_text, similarity_threshold, max_results)`, `autocomplete_search(search_prefix, max_results)`, `hybrid_search_fuzzy_semantic(query_text, query_embedding, max_results, rrf_k)` |
| [prefix_tsquery.sql](scripts/prefix_tsquery.sql) | `prefix_tsquery(config, text [, join])` |
| [setup.sql](scripts/setup.sql), [indexes.sql](scripts/indexes.sql) | Extensions, example tables, indexes |

Supabase `.rpc()` binds arguments by name, so a misspelled key fails at call
time:

```typescript
const { data, error } = await supabase.rpc('hybrid_search_fts', {
  query_embedding: embedding, // number[]
  query_text: userQuery,
  match_count: 10,
  fts_language: 'simple',
});

// Drizzle or node-postgres: send the vector as text and cast it
await db.execute(sql`SELECT * FROM match_documents(${JSON.stringify(embedding)}::vector, NULL, 10)`);
```

## References

- [pgvector.md](references/pgvector.md): types and dimension limits, HNSW
  tuning, planner choice, filters and thresholds, poolers, builds, operators.
- [keyword-search.md](references/keyword-search.md): tsquery parsing, accents
  and language configs, dead keyword arms, prefix matching, trigrams, ParadeDB.
- [hybrid-search.md](references/hybrid-search.md): fusion, hybrid versus vector,
  chunking, transcripts, off-language queries, synonym expansion.
- [reranking.md](references/reranking.md): choosing, depth, hardware, the
  relevance question, headroom, adoption.
- [evaluation.md](references/evaluation.md): two eval sets, bias, noise, and
  four ways a measurement misleads.

## Versions (checked 2026-09)

- **pgvector**: 0.8.0+ for iterative scans. Check current stable releases: 0.8.2 fixed a
  buffer overflow in parallel HNSW builds, 0.8.3 and 0.8.4 HNSW vacuum
  corruption and errors. Read the current index-fix and upgrade notes before
  upgrading. Releases ship as git tags only, so read the
  [CHANGELOG](https://github.com/pgvector/pgvector/blob/master/CHANGELOG.md),
  not the empty Releases tab.
- **pg_search**: 0.25+ depends on pgvector; install pgvector first. ParadeDB's
  API moves quickly; see [keyword-search.md](references/keyword-search.md#paradedb-pg_search).

## Related skills

| Need | Skill |
| --- | --- |
| General Postgres schema, indexes, RLS, pooling | `supabase-postgres-best-practices` |
| Chatbot orchestration, sessions, tool calls | `nextjs-chatbot` |
| Embedding calls through the AI SDK | `ai-sdk` |
