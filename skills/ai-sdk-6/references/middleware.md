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

Read [v6 middleware](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-ai-sdk-core/40-middleware.mdx)
and the installed source for an implementation matching this release.
