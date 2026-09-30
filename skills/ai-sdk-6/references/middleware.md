# AI SDK 6 middleware

Use `wrapLanguageModel` and the installed `LanguageModelV3Middleware` contract
when a model integration needs parameter transformation or generation/stream
interception. Prefer SDK built-ins for reasoning extraction, simulated streaming
or default settings when they meet the requirement.

Middleware order changes behavior. A wrapper must preserve stream part order,
usage and provider metadata; buffering a stream changes latency, cancellation
and memory use. Logging/caching examples are not safe defaults for private
prompts or multi-tenant results.

Use app/context APIs for request state where available rather than smuggling it
into provider options. Verify the relevant provider's accepted options.

Read [middleware docs](https://ai-sdk.dev/docs/ai-sdk-core/middleware) set to v6
and the installed source for an implementation matching this release.
