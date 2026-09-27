---
name: postgres-semantic-search
description: >-
  Builds and tunes search in PostgreSQL: pgvector semantic search, full-text
  and pg_trgm keyword search, hybrid RRF fusion, ParadeDB BM25, reranking and
  retrieval evals. Use when adding or debugging vector, hybrid, fuzzy or RAG
  retrieval in Postgres, even if the user only says search results are bad:
  HNSW, IVFFlat or halfvec choices, filtered or thresholded vector queries
  returning too few rows, a keyword arm that matches nothing, websearch_to_tsquery
  or unaccent problems, autocomplete and typo tolerance, non-English or
  inflected-language corpora, query translation, choosing or placing a
  cross-encoder reranker, or measuring Hit@K and MRR before adopting a change.
  For general Postgres schema, RLS or query tuning unrelated to retrieval, use
  supabase-postgres-best-practices.
---

# PostgreSQL Semantic Search

Decisions, measured findings and silent failure modes for search built on
Postgres, plus tested SQL building blocks in [scripts/](#scripts). Syntax the
official docs cover well is left to them; what is here goes wrong without an
error.

## Build order

1. Look at what users actually type: identifiers and codes, one-to-three-word
   terms, full questions, which languages. That decides which arms you need.
2. Start with vector search, and keep exact search (no index) as the recall
   baseline.
3. Build two eval sets, long questions and short terms, before tuning
   ([evaluation.md](references/evaluation.md)).
4. Add a keyword arm and fuse with RRF only where it beats vector-only on the
   queries that need it ([hybrid-search.md](references/hybrid-search.md)).
5. Add a reranker last, over the head of a good shortlist
   ([reranking.md](references/reranking.md)).

Change one thing at a time, and keep a change only if its gain exceeds the
run-to-run spread on both eval sets.

## Choosing

- **Column type by dimensions**, not provider: `vector(N)` indexes up to 2,000;
  up to 4,000 index a `halfvec` cast (or use a `halfvec` column); above that,
  binary quantization or Matryoshka truncation.
- **HNSW by default**, IVFFlat when memory or build time rules HNSW out. No row
  count decides it: measure recall and latency against exact search.
- **Models change every few months.** Pick embedding and reranker models from
  the provider's current docs, prefer multilingual models for non-English text,
  and evaluate on the target language before committing.
- **BM25 is not available everywhere**: managed hosts differ (Neon removed
  `pg_search`). Plain FTS with the fixes below is often enough.

## Silent failures

These return fewer rows, zero rows or plausible results, never an error.

pgvector ([pgvector.md](references/pgvector.md)):

- **An HNSW scan returns at most `hnsw.ef_search` rows** (default 40). A larger
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

- **Both stock tsquery parsers AND every term**, so a long question matches
  nothing. Rewrite `plainto_tsquery` output to OR and rank with `ts_rank_cd`.
- **`unaccent` merges distinct words** in Finnish, Swedish, German or Turkish.
  Fold only decorative accents, inside a text search configuration.
- **Zero-width characters** from CMS exports glue onto tokens and block
  stemming. Strip them at ingest and query time.
- **A generated tsvector column can silently become a plain NULL column** after
  an ORM migration. If hybrid and vector-only return identical lists, the
  keyword arm is dead.
- **Prefix matching in inflected languages** must OR-join terms and expand
  hyphenated tokens ([prefix_tsquery.sql](scripts/prefix_tsquery.sql)).
- **`%` compares whole strings**; use `<%` for prefixes and short queries
  against long text.

## Non-English and chunking

- **Cap chunks by the language's token rate.** Finnish runs about 2.5
  characters per token against English's 4; an English-derived cap overflows
  the embedding endpoint and can fail the whole batch.
- **Off-language queries**: hybrid silently degenerates to vector search.
  Translate the query into a sentence, not a keyword list (a keyword list
  scored 14 points below no translation), and consider two-pass fusion.
- **A multi-word synonym expansion** enters the tsquery as independent words,
  and its generic word takes over the ranking. Trim parts an order of
  magnitude commoner than the rest of their own phrase.
- **Transcripts**: chunk length barely changed which video was found. A second,
  fine-grained search over the subtitle cues inside the matched segment finds
  the moment.

Details and measurements: [hybrid-search.md](references/hybrid-search.md).

## Reranking

- **With a cross-encoder, rerank the top ~10 of a ~30-candidate shortlist**,
  not all 30. Reordering everything helped long questions but pushed the right
  result down for one-to-three-word topical queries.
- **The relevance question's wording can matter more than the model** (about
  thirty points on one corpus). Every criterion must be checkable from the text
  sent, and the source title belongs in the reranker input.
- **A 500M+ cross-encoder is not interactive on a small CPU pod.** Use a small
  model, a GPU or a hosted reranker.
- **Measure the shortlist ceiling first**: a reranker cannot recover what the
  first stage missed.
- Ship it as a runtime setting, off by default. If callers may choose a
  backend per request, allow only admin-enabled ones.

Numbers, model trade-offs and adoption rules: [reranking.md](references/reranking.md)
and [jev-rerank-bench](https://github.com/laguagu/jev-rerank-bench).

## Scripts

Run `setup.sql`, then `indexes.sql`, then the function files you need. They
assume `documents(id, title, content, metadata, embedding vector(1536))` and
`chunks(id, document_id, chunk_index, content, embedding)`: change the names
and dimension in every file together. Each script drops the older signatures it
replaces, so re-running them upgrades an existing database. None sets
`hnsw.ef_search`; the caller does.

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

- **pgvector**: 0.8.0+ for iterative scans. Run the newest 0.8.x: 0.8.2 fixed a
  buffer overflow in parallel HNSW builds, 0.8.3 and 0.8.4 HNSW vacuum
  corruption and errors. Releases ship as git tags only, so read the
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
