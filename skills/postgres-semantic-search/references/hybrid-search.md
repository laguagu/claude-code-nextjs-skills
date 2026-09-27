# Hybrid search, chunking and query handling

Read when fusing vector and keyword results, deciding whether a keyword arm
earns its latency, chunking documents or transcripts, handling queries in a
language other than the corpus, or expanding queries with synonyms.

## Contents

- [Fusion](#fusion)
- [Hybrid does not automatically beat vector search](#hybrid-does-not-automatically-beat-vector-search)
- [Chunks and context](#chunks-and-context)
- [Time-coded transcripts](#time-coded-transcripts)
- [Queries in another language](#queries-in-another-language)
- [Query expansion: a multi-word synonym is not one term](#query-expansion-a-multi-word-synonym-is-not-one-term)

## Fusion

Reciprocal rank fusion needs no score normalization: each arm adds
`weight / (k + rank)`, with `k = 60` by convention. Weight the arms rather than
switching to a linear mix of raw scores, which needs calibrated, comparable
scores to mean anything. Take each arm's candidates with `ORDER BY ... LIMIT`
and number them afterwards; a window function beside the `LIMIT` has to see
every row first, which rules out a top-N sort when the arm is not served by an
index. [scripts/hybrid_search_fts.sql](../scripts/hybrid_search_fts.sql) shows
the shape.

## Hybrid does not automatically beat vector search

On a ~54,000-chunk single-language corpus with 92 graded questions:

| Strategy | Recall@15 | MRR | Median latency |
| --- | ---: | ---: | ---: |
| Vector only | **75.0 %** | **0.557** | **76 ms** |
| Hybrid, RRF, vector weight 3 | 73.9 % | 0.519 | 681 ms |
| Hybrid, RRF, equal weights | 65.2 % | 0.357 | 702 ms |
| Keyword only (FTS) | 33.7 % | 0.144 | 602 ms |

- **Do not add the keyword arm on faith.** Equal weights were 10 points worse
  than vector alone. If you fuse, weight the vector side and compare with a
  vector-only baseline.
- **Do not delete it on these numbers either.** Its job is exact identifiers:
  part numbers, section references, names, product codes. A "find the chunk
  this question was generated from" eval set rarely contains them. Judge the arm
  on queries that need it.

## Chunks and context

- **Search chunks, return documents**: keep the best chunk per document inside
  each arm's candidates, then fuse by document
  ([scripts/hybrid_search_bm25.sql](../scripts/hybrid_search_bm25.sql)).
- **Contextual prefix.** Prepending the document title and section to each
  chunk before embedding resolves "section 28 says…". Anthropic measured 35 %
  fewer retrieval failures from contextual embeddings, 49 % with the context in
  the BM25 index as well. In a keyword index the repeated title words can also
  make every chunk of a document match a title term, so measure both
  placements on your own set. Regenerate prefixes when chunking changes.
- **Cap chunks by the language's token rate.** Finnish runs about 2.5
  characters per token against English's 4, so a character cap tuned on
  English is about twice too generous, the embedding endpoint rejects the
  chunk, and often the whole document's batch fails with it. Cap every chunk,
  whichever code path produced it.
- **Translated content**: add a `language_code` to the chunk table, include it
  in the uniqueness key, and scope ingest writes and deletes to one language.

## Time-coded transcripts

Video and audio search must find the right source and the right moment.
Measured on a Finnish lecture-transcript corpus (70 questions, 15 short terms):

- **Chunk length barely matters for finding the right video.** Windows from 20
  to 150 seconds found it about equally often; spend tuning effort elsewhere.
- **Find the moment with a second, fine-grained search.** After segment search
  picks a segment, score the subtitle cues inside it (± a few seconds) against
  the query and seek to the best one, falling back to the segment start. That
  beat shrinking the chunks.
- **Put the video title in the reranker input** with the segment text.

## Queries in another language

When the corpus is one language and a query arrives in another:

- **Hybrid silently becomes vector search.** A single-language FTS index scores
  near zero, so the fused list equals the vector ranking, with extra latency.
- **An off-language query costs about 12 points** even with a multilingual
  embedding model (Recall@15 73.9 % native, 62.0 % untranslated).
- **Translate into a sentence, not a keyword list.** A translated question
  reached 66.3 %. A translated list of search terms raised keyword recall from
  5.4 % to 20.7 % but embedded so badly that the pipeline fell to 47.8 %, 14
  points below not translating at all.
- **Two-pass fusion** recovers domain terms that cross-lingual embeddings blur:
  run hybrid search twice with the translated keyword text, once with the
  original-language embedding and once with the translated one, and RRF-merge
  the two. Cache translations and embeddings, and skip all of this when the
  query is already in the corpus language.

## Query expansion: a multi-word synonym is not one term

Adding the other name for a concept is the only way a keyword arm can connect
two names that share no prefix or trigram. The trap: tsquery builders OR-join
terms, so a multi-word expansion enters as one independent arm per word, and
its most common word takes over the ranking. Expanding `laptop` with
`portable computer` hands the keyword arm `computer`; on a ~2,000-segment
corpus the generic half of such a pair matched 47 segments against the
specific half's 1, and one off-topic document took six of the top ten.

A corpus-frequency cut for over-common query words does not catch this: it runs
before expansion, and 2 % of a corpus is under any sane floor. A word the user
typed is part of what they asked; an expansion word must earn its place.

Weigh a phrase's parts against each other, not against the query:

```text
for each multi-word expansion phrase:
    parts   = tokens with a known document frequency > 0
    if len(parts) < 2: keep the phrase unchanged
    rarest  = min(df of parts)
    drop    = parts where df >= rarest * 20          # an order of magnitude commoner
    remove drop from the keyword text                # the rarest part always stays
```

Comparing with the query's rarest term instead drops the wrong words: for
`sneakers` (df 1) expanded with `running shoes` (df 21 and 11), `running` is 21
times commoner than the typed term but the same order as its own partner.
Trim the keyword text only; the embedding pass keeps the whole phrase, where
the head noun places it correctly.
