# Reranking

Read before adding, choosing or tuning a reranker. A reranker reads the query
and each candidate together and reorders the head of a first-stage shortlist
(vector or hybrid search, typically ~30 candidates). It can only reorder what
it was given.

The findings below come from Finnish benchmarks in September 2026: a
lecture-transcript search (70 questions, 15 one-to-three-word terms) and legal
passages (public MuPLeR-fi, 200 queries). Models change quickly, so treat model
names as examples and re-measure current ones. Tables, latencies and costs are
in [jev-rerank-bench](https://github.com/laguagu/jev-rerank-bench).

## Contents

- [Choosing one](#choosing-one)
- [Rerank the head of the shortlist](#rerank-the-head-of-the-shortlist)
- [Where it runs](#where-it-runs)
- [The relevance question is part of the model](#the-relevance-question-is-part-of-the-model)
- [Know the headroom first](#know-the-headroom-first)
- [Adopting one](#adopting-one)

## Choosing one

| Kind | Examples (verify current options) | Trade-off |
| --- | --- | --- |
| Hosted cross-encoder | Cohere Rerank, Voyage rerank, ZeroEntropy | No infrastructure; per-search fee; candidate text leaves your network |
| Open weights | bge-reranker-v2-m3, Qwen3-Reranker, small mMiniLM cross-encoders | Text stays with you; model size decides whether it fits the latency budget. Check the licence: some popular rerankers (Jina's open weights) are non-commercial |
| Typed-judgment model | TypeSafe Jev | Hosted; you write the relevance question in plain language and get a probability you can gate on |
| Chat LLM as judge | any | On the legal passages two chat models (92–93 % R@1) trailed a cross-encoder and a typed-judgment model (95.5–96.5 %) at 5–10× the latency |

Check the project's data policy before choosing a hosted option; resolve
permission to send candidate text if it is unknown. Look up current model names in the provider's docs rather than
from memory. Prefer the framework's reranker adapter where one exists.

## Rerank the head of the shortlist

Compare shallow head reranking with full-shortlist reranking and the unchanged
first stage. The following depth results describe the measured transcript
corpus; model, query mix and deployment budget can favor another depth.

Reordering all 30 helped long questions but hurt one-to-three-word topical
terms: Hit@1 on the terms fell from 0.93 without reranking to 0.60–0.80 across
bge-reranker-v2-m3, Voyage and Qwen3-Reranker-8B. A short term comes up in
passing in many segments, and a cross-encoder scores "mentions X" rather than
"is about X", so it promotes the passing mentions. Reranking only the top 10
brought every model's terms back to 0.87–1.00, at a cost of up to 7 points on
the questions for the strongest models.

Reranking only the top 5 removed the remaining losses. On the transcript
search, six rerankers, from a small CPU cross-encoder to Qwen3-Reranker-8B, put
all 15 terms first at 5; at 10, four of them still lost one or two. Long
questions scored better at 5 for four of the six, and a CPU reranker's added
time fell to less than half.
Include depth 5 as a candidate for similar short-query workloads, and choose
from target-corpus measurements.

A judgment model whose question defined the short case (the term's subject is
a substantial topic of the segment, not a passing mention) did not show the
harm at either depth.

## Where it runs

Hosting decides the shortlist of models before quality does:

| Constraint | What fit (transcript search, head of 5) |
| --- | --- |
| CPU only | A ~120M multilingual cross-encoder (mmarco-mMiniLMv2). Right moment first on long questions 54 % → 60 %, about +0.3 s. 568M bge-reranker-v2-m3 took 9.6 s for 10 on 2 cores; Qwen3-Reranker-0.6B 21–25 s for 5 |
| Data-centre GPU (≥ 24 GB) | Qwen3-Reranker-8B: 71 % live, the only model clearly above the CPU model (11 won, 3 lost; offline 11 and 2, p ≈ 0.02), about +0.5 s. The 4B fits 16 GB and landed in between |
| Hosted API | No infrastructure; candidate text leaves your network. A hosted judgment model reached 67 % on the head of 10 |

A GPU that is only sometimes available works as the primary with the CPU model
as an automatic fallback on timeout. Measure p95 on the target hardware; a 568M
cross-encoder that is unusable on a small CPU pod takes tens of milliseconds on
a GPU.

If you self-host, load the model once at startup and put it behind a small
HTTP endpoint so the application treats it like a hosted reranker.

## The relevance question is part of the model

With a judgment model or an LLM judge you write the criteria, and the wording
can matter more than the model. On the legal passages, a question written for
another corpus required the passage to come from the document the query names;
these passages carry only a numeric id, so the criterion could never be met and
reranking fell below no reranking (R@1 73.0 % → 66.5 %). Rewritten for passage
relevance, the same model reached 95.5–96.5 %: about thirty points, more than
every model difference combined.

- Every criterion must be checkable from the text you send. If it depends on
  the source, send the source.
- Put the source title in the reranker input (document or video title plus the
  passage). This helps cross-encoders too.
- Define the short-query case explicitly if users type one-to-three-word terms.
- Hold out queries. A question tuned on the queries it is scored on gives an
  upper estimate.

## Know the headroom first

A reranker cannot recover a relevant passage that the first stage did not
return. Measure the shortlist ceiling (share of queries with any relevant
candidate in the top k) and report it beside every reranking number.

Example, 84 questions over a Finnish legal corpus, 30 candidates: R@10 rose from
58.3 % to 65.3 % with reranking, against a ceiling of 70.8 %. That is 92 % of
what any reranker could reach; the remaining 29 points belong to retrieval
(chunking, embeddings, query rewriting). A deeper shortlist (100) raised the
ceiling to 84.7 % but R@1 by only 1–3 points at 3.3× the cost: depth buys
recall, not precision.

## Adopting one

- **Benchmark on your own data.** Vendor numbers are mostly English and general
  domain. The regressions seen here came from reordering too deep for short
  queries, a model weak in the language (two open models scored below no
  reranking), and a mis-specified relevance question. Finnish text alone was
  not a cause: most rerankers improved the Finnish questions by 6–24 points.
- **Agree the acceptance rule before measuring**, for example "must not make
  short terms worse, and must answer within the timeout on the target
  hardware". Require a gain larger than your run-to-run spread, on both a long
  and a short eval set ([evaluation.md](evaluation.md)).
- **Make it configurable when useful, with a measured default**, so switching or disabling it
  needs no deploy. On failure, keep the first-stage order, and skip a failing
  backend for a while so an outage does not add a timeout to every search.
- **If callers can pick a reranker per request**, allow only backends the admin
  enabled, so an API client cannot send your documents to a third party nobody
  approved.
- **Skip it** for autocomplete, exact identifier lookups, and when the ceiling
  leaves little headroom. Cost grows with how much text it reads.
