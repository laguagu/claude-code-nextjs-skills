# Evaluating retrieval changes

Read before adopting any retrieval change: embedding model, chunking, fusion
weights, query rewriting, translation or a reranker. Vendor and paper
benchmarks are mostly English and general domain, and do not predict a
multilingual or domain corpus.

## Contents

- [Two eval sets, and they disagree](#two-eval-sets-and-they-disagree)
- [Building the sets](#building-the-sets)
- [Noise and what a delta means](#noise-and-what-a-delta-means)
- [Four ways a measurement misleads](#four-ways-a-measurement-misleads)
- [Gotchas](#gotchas)

## Two eval sets, and they disagree

Real users mostly type one to three words (93 % of searches in one production
log). An LLM-generated set is made of well-formed questions. A change can help
one population and hurt the other: dropping an over-common word from short
queries helped the short set and hurt the long one, and a cross-encoder
reordering 30 candidates did the reverse. Either set alone gave the wrong
answer once. Keep both:

| Set | Shape | Good for |
| --- | --- | --- |
| Long | 70–500 generated natural-language questions | broad regression cover |
| Short | 15–50 hand-graded domain terms of one to three words | the shape users actually type |

## Building the sets

- **Long set**: sample chunks with enough real text (a few hundred
  characters), from documents still in use, and have a cheap model write one
  natural question each chunk answers. Store question, expected document and
  expected chunk. Under ~50 questions is noise; a few hundred is a useful
  signal.
- **Bias**: a question generated from a chunk is unusually close to that chunk
  in embedding space. Vector and RRF baselines look better than in production,
  and rerankers and query rewriters look worse, because they reshuffle a
  ranking the bias already made near-optimal. Mix in 30–50 hand-written,
  live-style questions and compare deltas, not absolute scores.
- **Apply production filters** (date, category, access) when sampling, or Hit@K
  collapses for reasons unrelated to ranking.
- **Metrics**: Hit@K (K = 1, 5, 10) and MRR on the retrieval side; p50 and p95
  latency with cold and warm runs labelled separately. Re-sample when the corpus
  drifts.

## Noise and what a delta means

- A short set with no LLM on the request path is often deterministic, so a
  one-point move is real. A long set that passes through a query rewriter,
  intent splitter or translation gate swung ±3 points between runs of identical
  code. Measure your run-to-run spread once, write it next to the set, and do
  not believe a smaller delta.
- "No change on the long set" is evidence only if some query in it exercises
  the changed code. Check; otherwise say it only rules out global damage.
- Set the minimum useful gain and the latency and cost budget before the
  experiment. Report sample size, per-query wins and losses, and an interval
  (a paired bootstrap is enough).

## Four ways a measurement misleads

1. **An isolated arm is not the pipeline.** Making the keyword arm more precise
   on its own (Hit@1 0.357 → 0.371) lost end to end (Hit@5 0.790 → 0.768 over
   four runs): that arm was the only lexical bridge for queries whose terms
   could not prefix-match their inflected forms, and fusion was using its noisy
   tail. Confirm every change on the full pipeline.
2. **Better retrieval can produce worse answers.** Raising top-k from 15 to 30
   lifted Recall@30 by 5.4 points and lowered the share of generated claims
   supported by a retrieved source from 82.1 % to 78.8 %. Before changing how
   much text reaches the model (top-k, chunk size, rerank depth), run a judged
   answer-quality pass. For judging whether a passage supports a claim, one
   demanding yes/no question that lists what must match (numbers, conditions,
   actors, *may* versus *must*) beat a supports/contradicts/unrelated question
   (88.1 % against 81.8 % balanced accuracy on subtly wrong Finnish claims).
3. **An offline sweep predicts ordering, not production numbers.** A sweep at
   full precision without the index showed one model 2 points ahead of its
   quantized form. Through the production pipeline both found the same
   documents, and the quantized one ranked them better, ran 40 % faster and
   used a quarter of the memory. Use sweeps to rank candidates, then confirm.
4. **The obvious improvement is often noise, a regression, or unmeasured.** Of
   three changes that looked right on one project's sweep, one was noise, one
   regressed, and one depended on a measurement nobody had made. Rejected
   changes with written reasons are a good outcome.

## Gotchas

- Bigint ids come back as strings from some drivers; compare
  `String(a) === String(b)` when computing ranks.
- If production keeps the HNSW index warm, benchmark warm; otherwise you
  measure a state users never see. Discard the first cold query either way.
