# AI SDK 6 generation and output

Use `generateText` or `streamText` with the provider package already used by
the app. V6 uses `system`, `stopWhen` and `stepCountIs`; do not substitute
v7 names or assume they exist in this major.

For schema output, use `Output.object`, `array`, `choice` or another supported
output specification. Prefer validated output to parsing text that merely
looks like JSON. Schema validity does not prove semantic correctness.

A `useChat` response needs UI-message streaming; a plain text stream is a
different protocol. V6 exposes result helpers such as
`toUIMessageStreamResponse`, `fullStream` and `consumeStream`. Streaming
completion is `onFinish`; final result properties may be promises.

Multi-step `usage`, tool calls and outputs on the result have final-step
semantics; `totalUsage` and `steps` provide aggregates/history. Match the field
to the app's accounting or persistence requirement.

Resolve provider options, callbacks and structured-stream behavior from the
installed docs/types or [AI SDK Core](https://ai-sdk.dev/docs/ai-sdk-core/overview)
with v6 selected.
