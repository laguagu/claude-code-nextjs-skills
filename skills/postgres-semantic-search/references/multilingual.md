# Multilingual and non-English retrieval

Rules for corpora in Finnish, German, French, Spanish and other non-English
languages, and for corpora queried in several languages. Read this when the
corpus is not English prose, when queries arrive in a different language than
the content, or when the keyword arm silently returns zero hits.

## Contents
- FTS language configuration, unaccent, invisible characters
- Long questions, chunk caps, prefix tsquery
- Compound words, synonym expansion, query translation, ParadeDB stemmers
- Embedding model choice and cross-language RRF fusion
- Per-language indexing for translated content

## Rules

- **FTS language config**: pass the matching language to `to_tsvector(language, text)` to apply the built-in snowball stemmer (e.g., `'finnish'` handles `opiskelija → opiskelij`). For mixed-language corpora, use `'simple'` and rely on prefix/trigram fallbacks instead. A *per-row* language config cannot live in a generated tsvector column — generated columns require IMMUTABLE expressions, and casting a text column to `regconfig` is only STABLE (a catalog lookup), so the expression is rejected — write the tsvector at ingest instead.
- **Combine stemmer + unaccent only where diacritics are decorative** (French, Spanish, Portuguese: "café" matches "cafe"). Never for languages where they are distinct letters (Finnish, Swedish, German, Turkish…): unaccent merges different words (`säästää`/`saastaa`) and degrades the stemmer. See [hybrid-search.md → Custom FTS configuration](hybrid-search.md#custom-fts-configuration-eg-language--unaccent).
- **Strip invisible characters at ingest and query time.** Zero-width spaces and joiners (U+200B, U+200C/D, U+FEFF) from CMS editors glue onto words; Postgres does not treat them as whitespace, so the token skips stemming and never matches. Found on a real export in 10 titles and 23 chunks. See [hybrid-search.md → Invisible characters](hybrid-search.md#invisible-characters-silently-defeat-stemming).
- **Long plain-language questions may need an AND→OR tsquery rewrite.** Every parser conjoins bare terms, so a nine-content-word question can leave the keyword arm with zero hits. For input without explicit `OR`, quotes, or `-`, parse with `plainto_tsquery`, then `replace(…::text, ' & ', ' | ')::tsquery` and let `ts_rank_cd` rank. Preserve `websearch_to_tsquery` unchanged when the UI exposes its operators. Details in [hybrid-search.md → Query parsers](hybrid-search.md#query-parsers-websearch_to-tsquery-vs-plainto-tsquery).
- **Size chunk caps by the language's token rate, not English's.** Finnish runs ~2.5 characters per token against English's ~4, so a character cap derived from English is about twice too generous and the embedding endpoint rejects the oversized chunk — often failing the whole document's batch. Cap every chunk regardless of which code path produced it.
- **Prefix tsquery** for languages with rich inflection: build the tsquery by hand with `:*` on each token, since `websearch_to_tsquery` cannot emit it. Use the hardened `prefix_tsquery` in [fuzzy-search.md](fuzzy-search.md#prefix-matching-for-agglutinative-languages) rather than writing one — a naive version fails silently in three separate ways, each returning zero rows rather than an error.

- **Compound-word fallback**: pair semantic search with `pg_trgm` similarity to catch compound-word misses (e.g., a query for `"ammattikorkea"` should still find `"ammattikorkeakoulu"`).
- **Synonym expansion is how the keyword arm learns that two names mean one thing** — the embedding carries the relationship, the keyword arm cannot, because the two names share no prefix and no trigram. But a **multi-word** synonym is OR-joined into the tsquery, so its generic half becomes an independent match arm and can take over the ranking. Weigh a phrase's parts against each other, not against the query, and trim the keyword text only: [hybrid-search.md → Query expansion](hybrid-search.md#query-expansion-a-multi-word-synonym-is-not-one-term).
- **Translate an off-language query into a sentence, not a keyword list** — the list form helps the keyword arm and costs more than it gains overall ([measured](hybrid-search.md#translate-to-a-sentence-not-to-a-keyword-list)).
- **Stemmer in a ParadeDB index**: apply it as a cast at index time — `(content::pdb.simple('stemmer=finnish'))` or `(content::pdb.unicode_words('stemmer=finnish'))`. The JSON-object tokenizer config (`{"type": "default", "stemmer": …}`) is the pre-v2 API and no longer appears in the docs; the untokenized option is now `pdb.literal`, not `raw`.
- **Multilingual embeddings**: prefer models explicitly trained on your target language(s). English-only embeddings often miss inflected forms and compound words. The gap can be large — several percentage points of Hit@5 on non-English retrieval is realistic. Benchmark your specific language + domain before committing.
- **Cross-language RRF fusion for monolingual corpora**: when the corpus is
  one language and queries arrive in many, run two hybrid passes per
  off-language query (original-language embedding + translated-language
  embedding, same FTS text) and RRF-merge. Recovers domain terms that
  cross-lingual embeddings collapse. See [hybrid-search.md →
  Cross-language RRF fusion pattern](hybrid-search.md#cross-language-rrf-fusion-pattern).

- **Per-language indexing for multilingual content**: when translated
  content exists, add `language_code` to the chunk table (default to the
  original language so existing rows backfill), include it in the
  uniqueness constraint, and scope ingest writes/deletes to one language.
  Search stays language-agnostic; native-language queries hit native
  embeddings directly.

  ```sql
  ALTER TABLE chunks ADD COLUMN language_code TEXT NOT NULL DEFAULT 'en';
  ALTER TABLE chunks DROP CONSTRAINT chunks_doc_chunk_unique;
  ALTER TABLE chunks ADD CONSTRAINT chunks_doc_chunk_lang_unique
    UNIQUE (doc_id, chunk_index, language_code);
  CREATE INDEX chunks_doc_lang_idx ON chunks (doc_id, language_code);
  ```
