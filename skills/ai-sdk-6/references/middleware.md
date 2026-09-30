# AI SDK 6 middleware

Use `wrapLanguageModel` and the installed `LanguageModelV3Middleware` contract
(`specificationVersion: 'v3'`) when a model integration needs parameter
transformation or generation/stream interception. Built-ins include
`extractReasoningMiddleware`, `simulateStreamingMiddleware`,
`defaultSettingsMiddleware` and `extractJsonMiddleware`.

Middleware order changes behavior. A wrapper must preserve stream part order,
usage and provider metadata; buffering a stream changes latency, cancellation
and memory use. Logging/caching examples are not safe defaults for private
prompts or multi-tenant results.

For request metadata consumed by v6 middleware, the documented channel is
`providerOptions.<middlewareKey>`; read it in `transformParams`. Check the
provider contract before forwarding custom options downstream.

Read [v6 middleware](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-ai-sdk-core/40-middleware.mdx)
and the installed source for an implementation matching this release.
