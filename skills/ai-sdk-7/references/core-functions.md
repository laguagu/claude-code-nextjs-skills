---
title: Core Functions in AI SDK 7
description: generateText, streamText, output, settings, streams, and result shape.
---

# Generation, stream and result contracts

Use text functions with `Output` for validated structured output. Keep system
instructions in top-level `instructions`; v7 rejects system messages in input
history by default. `allowSystemInMessages` is an explicit compatibility option
for trusted history, not browser-controlled instructions.

`streamText` exposes `stream` instead of `fullStream`. Its `onChunk` can
receive boundary, lifecycle and terminal parts as well as text/tool data.
Narrow the part before processing it.

Result response methods (`toUIMessageStreamResponse` etc.) are deprecated.
Use `createUIMessageStreamResponse({ stream: toUIMessageStream({ stream:
result.stream, originalMessages, onEnd }) })`, or `toTextStream` +
`createTextStreamResponse` for plain text. The server output must match the
client transport. Provider-executed tools and file/reasoning parts need
handling beyond text deltas.

Top-level usage/content/tool arrays aggregate all steps. Use `finalStep`
(awaited for a stream) for final-step metadata and usage, and
`result.responseMessages` (not `step.response.messages`) for the full
assistant/tool history. Request/response bodies are omitted unless
`include: { requestBody, responseBody }` (`responseBody`: `generateText` only).

Use top-level `reasoning` (`'none'` … `'xhigh'`, default
`'provider-default'`) only when supported; overlapping provider settings take
precedence. `timeout` takes ms or `{ totalMs, stepMs, chunkMs, toolMs,
tools: { <name>Ms } }`; a tool timeout becomes a tool error.

Find exact options/defaults in `docs/03-ai-sdk-core/` (`25-settings`,
`26-reasoning`), `docs/07-reference/01-ai-sdk-core/` or
[AI SDK Core](https://ai-sdk.dev/docs/ai-sdk-core/overview). For renamed fields
or changed semantics read the [migration reference](migration-v6-to-v7.md).
