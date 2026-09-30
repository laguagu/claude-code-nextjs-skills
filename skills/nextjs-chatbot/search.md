# Retrieval for chatbot answers

Choose retrieval from the data and real questions. Structured application
records often benefit from SQL/FTS/trigram search; semantic search can help
paraphrases and unstructured passages. Neither choice guarantees grounded
answers or should be imposed on every chatbot.

Parse supported structured filters into a validated schema and enforce them
deterministically on the server. Keep authorization and tenant predicates
independent of model-generated filters. Return stable record/source IDs and
only the fields needed for the answer.

Parameterize queries. Allowlist columns/operators for dynamic sorting or
filtering, bound result counts and set timeouts. Distinguish no matches,
partial coverage and a failed source; the agent must not interpret an
incomplete result set as proof that an item does not exist.

Ground factual names, prices, dates and availability in authoritative records.
Give the agent concise domain-specific guidance about unsupported claims and
when another lookup is appropriate; avoid a universal “repeat only verbatim
tool text” rule that prevents useful explanation.

Evaluate retrieval and final answer support separately. Include identifiers,
short terms, full questions, target languages and unavailable items. Measure
latency and compare with the simplest useful baseline before adding
embeddings, fusion, query rewriting or a reranker.

Use `postgres-semantic-search` for PostgreSQL retrieval constraints and
[testing.md](testing.md) for model/retrieval evaluation.
