# AI SDK 6 generation and output

Use `generateText` or `streamText` with the provider package already used by
the app. V6 uses `system`, `stopWhen` and `stepCountIs`; do not substitute
v7 names or assume they exist in this major.

For schema output, pass `output: Output.object({ schema })` (or `array`,
`choice`, `json`) and read `result.output`; `experimental_output` is the
deprecated name. Schema validity does not prove semantic correctness.

A `useChat` response needs UI-message streaming; a plain text stream is a
different protocol. V6 exposes result helpers such as
`toUIMessageStreamResponse`, `fullStream` and `consumeStream`. Streaming
completion is `onFinish`; final result properties may be promises. Smooth text
deltas with `experimental_transform: smoothStream()` (also accepted by
`createAgentUIStreamResponse`).

Multi-step `usage`, tool calls and outputs on the result have final-step
semantics; `totalUsage` and `steps` provide aggregates/history. Match the field
to the app's accounting or persistence requirement.

Resolve provider options, callbacks and structured-stream behavior from
`docs/03-ai-sdk-core/` (`05-generating-text`, `10-generating-structured-data`,
`25-settings`), provider `docs/`, or the
[v6 Core guide](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-ai-sdk-core/01-overview.mdx).
