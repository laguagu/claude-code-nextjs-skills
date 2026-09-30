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

Result response helpers are deprecated. Use
`createUIMessageStreamResponse({ stream: toUIMessageStream({ stream: result.stream, originalMessages, onEnd }) })`
for UI messages, or `toTextStream` + `createTextStreamResponse` for plain text.
The server output must match the client transport. Provider-executed tools
and file/reasoning parts need handling beyond text deltas.

Top-level usage/content/tool arrays aggregate all steps. Use `finalStep`
(awaited for a stream) for final-step metadata and usage. Choose intentionally
for accounting, storage and rendering.

Use top-level `reasoning` only when supported; overlapping provider settings
take precedence. Configure timeouts for the actual operation, distinguishing
total, step, chunk and tool deadlines where the installed API supports them.

Find exact options/defaults in installed docs/types and
[AI SDK Core](https://ai-sdk.dev/docs/ai-sdk-core/overview). For renamed fields
or changed semantics read the [migration reference](migration-v6-to-v7.md).
