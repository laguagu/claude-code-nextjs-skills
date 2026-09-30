# Chatbot verification

UI transitions, retrieval quality and model behavior are separate checks.
Choose checks for the changed behavior, using the project's existing tooling.

## Interface and transport

Drive representative typed messages through the actual installed renderer and
chat lifecycle. For deterministic `useChat` UI tests, consider the optional
[`createChat` helper](https://ui.shadcn.com/docs/helpers/ai-sdk) from
`@shadcn/helpers/ai-sdk`; check compatibility with the installed SDK. It exercises
the UI lifecycle without a model or API key, while backend checks remain separate.

Exercise partial input, tool completion, approval/denial, empty results,
safe errors, cancellation, restored history and rapid conversation switching.
Verify a second turn after reload, readable Markdown, scroll anchoring, keyboard
focus and mobile composer reachability. An agent-level eval cannot detect
controls hidden behind a loading animation.

Verify the production stream path: first visible output, proxy buffering,
timeout/disconnect behavior and terminal in-stream errors. A successful HTTP
status alone does not prove completion.

## Model and retrieval

Use cases representative of the supported domain: answerable questions,
missing records, ambiguous requests, off-topic requests and prompt injection
through both user input and retrieved content. Assert supported claims,
appropriate tool choice, permissions and source coverage rather than exact
prose.

When changing retrieval/model/prompt behavior, compare baseline and candidate
on the same fixtures. Include short and long queries and target languages.
Repeat where run-to-run variance could change the conclusion, recording model
version/settings, latency, cost and per-case failures. Judge answer support
separately from retrieval rank.

Keep real secrets and customer content out of fixtures and captures. Report
what ran, what failed and which provider/deployment checks were unavailable.
Do not add benchmark commands or a fixture schema for files that the project
does not actually have.
