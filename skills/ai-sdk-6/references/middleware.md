# AI SDK 6 middleware

Use `wrapLanguageModel` and the installed `LanguageModelV3Middleware` contract
(`specificationVersion: 'v3'` is required) when a model integration needs
parameter transformation or generation/stream interception. Prefer built-ins
when they fit: `extractReasoningMiddleware`, `simulateStreamingMiddleware`,
`defaultSettingsMiddleware`, `extractJsonMiddleware`.

Middleware order changes behavior. A wrapper must preserve stream part order,
usage and provider metadata; buffering a stream changes latency, cancellation
and memory use. Logging/caching examples are not safe defaults for private
prompts or multi-tenant results.

Per-request metadata reaches v6 middleware through
`providerOptions.<middlewareKey>` (the documented pattern).

Read `docs/03-ai-sdk-core/40-middleware.mdx` and `src/middleware/`, or
[v6 middleware](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-ai-sdk-core/40-middleware.mdx).
