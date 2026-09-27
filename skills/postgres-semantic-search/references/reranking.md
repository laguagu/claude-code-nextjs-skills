# Re-ranking Guide

## Contents

- [Choosing a reranker](#choosing-a-reranker)
- [Rerank the head, not the whole shortlist](#rerank-the-head-not-the-whole-shortlist)
- [Measured results](#measured-results)
- [Where it runs: CPU, GPU or hosted](#where-it-runs-cpu-gpu-or-hosted)
- [Judgment models: the question is part of the model](#judgment-models-the-question-is-part-of-the-model)
- [Production rules (apply to ANY reranker)](#production-rules-apply-to-any-reranker)
- [When NOT to re-rank](#when-not-to-re-rank)
- [Report the shortlist ceiling with every number](#report-the-shortlist-ceiling-with-every-number)
- [Rerankers can regress — benchmark first](#rerankers-can-regress--benchmark-first)

Re-ranking is a two-stage pattern: a fast first stage (vector or hybrid search)
returns a shortlist, usually around 30 candidates, and a slower model scores each
query–candidate pair together and reorders the top of that list.

The measured numbers below (September 2026; models rotate, so re-measure current
versions) come from two Finnish benchmarks, written up in
[jev-rerank-bench](https://github.com/laguagu/jev-rerank-bench) (README sections
1, 4 and 5):

- **Lecture transcripts**: a Finnish lecture-transcript search corpus, 70
  natural-language questions and 15 one-to-three-word terms, Hit@1 over a frozen
  top-30 hybrid shortlist. A relevant segment was in the shortlist for 95.7 % of
  the questions and for every term.
- **Legal passages**: Finnish legal passages (public MuPLeR-fi), 200 queries over
  a 30-candidate hybrid shortlist.

## Choosing a reranker

| Option | Examples (verify current models) | Trade-off |
| --- | --- | --- |
| Hosted cross-encoder | Cohere Rerank, Voyage rerank, ZeroEntropy zerank | No infrastructure, pay per search; candidate text leaves your network |
| Open weights, Apache-2.0 | `bge-reranker-v2-m3` (568M), `Qwen3-Reranker` 0.6B / 4B / 8B, `mmarco-mMiniLMv2-L12-H384-v1` (118M) | Text stays with you; model size decides whether it fits the latency budget ([below](#where-it-runs-cpu-gpu-or-hosted)) |
| Open weights, non-commercial | Jina reranker v2 / v3 | CC-BY-NC-4.0: self-hosting in a commercial product needs a licence; the hosted Jina API is the commercial route |
| Typed-judgment model | TypeSafe Jev ([rerank cookbook](https://docs.typesafe.ai/cookbooks/rerank_typesafe)) | Hosted; you write the relevance question in plain language, and it returns a probability you can gate on. Batch candidates into one request |
| General chat LLM as judge | any chat model | On the legal passages two chat models (92–93 % R@1) trailed a cross-encoder and a typed-judgment model (95.5–96.5 %) at 5–10× the latency |

Ask the user's preference, including whether text may leave their network. Check
the provider's docs for the current model name; names rotate every 6–12 months, so
never hard-code one guessed from training data.

## Rerank the head, not the whole shortlist

Retrieve about 30 candidates for recall, then let a cross-encoder rerank only the
top ~10 and keep the rest in first-stage order. Measure the depth on both a
long-question and a short-term eval set ([evaluation.md](evaluation.md)).

On the lecture transcripts, reordering all 30 candidates helped long questions and
hurt one-to-three-word topical terms badly (Hit@1 from 0.933 without reranking):
`bge-reranker-v2-m3` to 0.600, Voyage `rerank-2.5` to 0.800, `Qwen3-Reranker-8B` to
0.667. A short term comes up in passing in many segments, and a cross-encoder,
which partly behaves like a semantic BM25, scores "mentions X" rather than "is
about X", so it promotes the passing mentions.

Reranking only the top 10 removed that harm (bge-m3 0.933, Voyage 1.000,
`Qwen3-Reranker-4B` 1.000) at a small cost on the questions: the stronger
cross-encoders lost up to 7 points against reordering all 30 (Voyage 0.700 →
0.643).

A typed-judgment model whose relevance question defines the short-term case — *the
term's subject is a substantial topic of the segment, not a passing mention* — did
not show the harm: 1.000 on the terms at both depths.

## Measured results

Offline, lecture transcripts, Hit@1, same top-30 shortlist for every model. The
typed-judgment question was written against these same queries, so read its rows
as an upper estimate:

| Reranker | Questions, rerank 30 | Questions, rerank top 10 | Terms, rerank 30 | Terms, rerank top 10 |
| --- | ---: | ---: | ---: | ---: |
| none | 0.543 | 0.543 | 0.933 | 0.933 |
| TypeSafe Jev (hosted) | 0.629 | **0.657** | **1.000** | **1.000** |
| Voyage `rerank-2.5` (hosted) | **0.700** | 0.643 | 0.800 | **1.000** |
| `Qwen3-Reranker-0.6B` | 0.614 | 0.614 | 0.800 | 0.933 |
| `bge-reranker-v2-m3` | 0.614 | 0.600 | 0.600 | 0.933 |
| `mmarco-mMiniLMv2-L12-H384-v1` | 0.600 | 0.571 | 0.733 | 0.867 |
| `mxbai-rerank-base-v2` | 0.543 | 0.529 | 0.733 | 0.933 |
| `gte-multilingual-reranker-base` | 0.343 | 0.414 | 0.600 | 0.933 |
| Laya decision model | 0.114 | 0.186 | 0.333 | 0.867 |
| `Qwen3-Reranker-4B` (GPU) | — | 0.657 | — | 1.000 |
| `Qwen3-Reranker-8B` (GPU) | 0.786 | 0.714 | 0.667 | 0.933 |

`gte-multilingual-reranker-base` and the Laya model scored well below no reranking
on the questions at either depth, and `mxbai-rerank-base-v2` did not beat it. The
Laya model also took 20–26 s per query on a CPU.

End to end in production on the same corpus (top 10 for the local model, the
typed-judgment model as shipped):

| Reranker | Questions Hit@1 | Terms Hit@1 | Added per search |
| --- | ---: | ---: | ---: |
| none | 0.543 | 0.933 | — |
| TypeSafe Jev (hosted) | 0.643–0.657 | 1.000 | +0.44 s |
| `mmarco-mMiniLMv2-L12-H384-v1`, 2-core CPU pod | 0.600 | 1.000 | +1.5 s |

Run-to-run spread was one query (1.4 points on the questions); both gains are
several times that.

## Where it runs: CPU, GPU or hosted

Per call, candidates cut to about 1,200 characters:

| Model | 2-core CPU container, 10 docs | 30 docs | GPU (one MI250X GCD, bf16), 10 docs |
| --- | ---: | ---: | ---: |
| `mmarco-mMiniLMv2-L12-H384-v1` (118M) | 1.6 s | 4.7 s | — |
| `bge-reranker-v2-m3` (568M) | 9.6 s | 28 s | 43 ms |
| `Qwen3-Reranker-0.6B` | slower than bge-m3 | | 190 ms |
| `Qwen3-Reranker-4B` | — | | 0.73 s (~14 GB at a 30-doc batch) |
| `Qwen3-Reranker-8B` | — | | 1.14 s (~23 GB at a 30-doc batch) |

**Rule**: a 500M+ cross-encoder is not an interactive reranker on a small CPU pod.
Use a small model and accept its lower quality, put the model on a GPU, or use a
hosted reranker. With a 6 s budget on the 2-core pod only the 118M model fit; a
hosted reranker costs a per-search fee and sends candidate text off your network.

If self-hosting:

- **Load the model once at startup**, not per request; loading takes seconds.
- Cap the text per candidate, and expose the model as a small HTTP service
  (`POST /rerank` with `{ query, documents, top_n }`) so the application applies
  the same failure rules as to a hosted reranker.

## Judgment models: the question is part of the model

With a typed-judgment model or an LLM judge, you write the relevance criteria. On
the legal passages, the wording of that question moved R@1 by about thirty points,
more than every model difference combined. A question written for another corpus
required the passage to come from the document the query names; these passages
carry only a numeric id, so the criterion could never be satisfied, and reranking
fell *below* no reranking (73.0 % → 66.5 % R@1, one call per candidate). Rewritten
for passage relevance, the same model reached 95.5–96.5 %.

- **Every criterion must be checkable from the text you send.** If it depends on
  the source, send the source.
- **Put the source title in the reranker input** (document or video title plus the
  passage). This applies to cross-encoders too.
- **Define the short-query case** explicitly, as in the example above, if users
  type one-to-three-word terms.
- **Hold out queries.** A question written against the same queries it is scored on
  gives an upper estimate, as with the lecture-transcript rows above.

## Production rules (apply to ANY reranker)

Re-ranking is an enhancement, not a requirement:

1. **Fail open.** Missing key, HTTP error (including 429), timeout, malformed
   response or empty input → return `null`; the caller keeps the retrieval order.
   Never throw. Log at `warn` with the backend name and reason.
2. **Short per-backend timeout** (`AbortSignal.timeout(...)`), sized to the backend:
   a few seconds for a hosted API, more for a local CPU model.
3. **Cooldown after a failure** (~60 s): skip the backend so an outage does not add
   a full timeout to every search.
4. **Short score cache** keyed by query plus candidate ids, so paging and repeated
   searches do not pay again.
5. **Runtime admin setting, default off.** Switching the reranker, or turning it
   off, should not need a deploy.
6. **Gate per-request overrides.** If the API lets callers pick a reranker per
   request, allow only backends the admin enabled, so an API partner cannot route
   your data to a third party the admin did not choose.

Prefer the framework's reranker adapter (AI SDK, LangChain, LlamaIndex) when it
exists, and wrap it with the rules above. For a direct HTTP call, read the
provider's current request shape.

## When NOT to re-rank

- Real-time autocomplete (latency critical).
- Very large candidate sets (> 100 docs): pre-filter first; cost grows with what
  the reranker reads.
- Exact identifier lookups: the keyword arm already ranks them right.
- When the shortlist ceiling leaves little headroom (next section).
- Full-depth reordering of one-to-three-word topical queries, unless the model's
  criteria define that case ([above](#rerank-the-head-not-the-whole-shortlist)).

## Report the shortlist ceiling with every number

A reranker only reorders the candidates stage 1 handed it. So the fraction of
queries whose shortlist contains a relevant passage **at all** is a hard ceiling
on every metric, and a recall number without it cannot be read.

Measure it once per first stage: the share of queries where any candidate in the
top *k* is relevant. Then report the pair.

Worked example, 84 questions over a Finnish legal corpus, 30 candidates:

| | R@10 | ceiling | share of ceiling reached |
| --- | ---: | ---: | ---: |
| hybrid, no rerank | 58.3 % | 70.8 % | 82 % |
| hybrid + reranker | 65.3 % | 70.8 % | **92 %** |

"65.3 %" reads as mediocre and is actually near-exhaustion: 21 of the 72 scorable
queries never had the answer in the shortlist, and no reranker can retrieve what
it was not given. Deepening the shortlist to 100 raised the ceiling to 84.7 % and
R@10 by seven points, while R@1 moved one to three at 3.3× the cost — depth buys
recall, not precision.

**Rule**: before tuning a reranker, compute how much headroom it has. The
remaining gain available to *any* reranker is ceiling minus current score —
so when that gap is small, further reranking work cannot pay, however good the
next model is, and the effort belongs in stage 1 (chunking, embedding model,
query rewriting, candidate depth). Compare the two gaps rather than reaching for
a fixed cut-off: the example above has 5.5 points left to reranking and 29.2 to
retrieval.

## Rerankers can regress — benchmark first

Vendor-claimed "+N pp" is usually measured on English, general-domain data, and a
reranker can make your search worse. The regressions measured above had three
causes: reordering too deep for short topical queries, a weak model for the
language (two open models below no reranking), and a mis-specified relevance
question. Non-English text alone was not one: most rerankers tested improved the
Finnish questions by 6–24 points of Hit@1.

**Rule**: never ship a reranker from a paper or vendor benchmark alone. A/B it on
your own long and short eval sets ([evaluation.md](evaluation.md), including its
bias warning about LLM-generated questions). Agree the acceptance rule before
measuring — for example "must not make the short terms worse and must answer
within the timeout on the target hardware" — and require a gain larger than your
run-to-run spread, with p95 latency within the product budget.
