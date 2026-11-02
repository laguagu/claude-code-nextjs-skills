# Web search

Use external web search when the supported task needs public or current
information beyond the application's authoritative sources. Decide allowed
source scope and provider data policy before adding it.

Check the selected model, endpoint and installed provider for native search
support. Capabilities differ between providers and deployments; Azure names
are user-defined, so do not infer endpoint support from a name regex. A
third-party search SDK or server-side fetch is an alternative when it fits the
task.

Treat search results and fetched text as untrusted data. Keep tool permissions
and trusted instructions separate from retrieved content. Validate fetch
destinations, redirects and response size to prevent access to private network
resources or unbounded downloads. Apply timeouts and bound source counts.

Preserve source URLs, relevant timestamps and citation metadata through the
tool/UI path. Provider source parts reach `useChat` as `source-url` or
`source-document` only when the UI stream sets `sendSources: true` (default
`false`); custom tool citations need their own typed result path. Answer with
useful sources and distinguish fresh evidence,
stale evidence, missing coverage and tool failure.

Cache by source/query policy and the required freshness, not a universal
one-hour TTL. Include identity/authorization in keys where results differ.
Search failure should not silently produce a fabricated answer.

Use the installed provider docs and the
[AI SDK provider index](https://ai-sdk.dev/providers) for current capability
contracts; use [search.md](search.md) for application retrieval.
