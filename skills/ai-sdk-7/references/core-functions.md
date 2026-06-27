---
title: Core Functions in AI SDK 7
description: generateText, streamText, output, settings, streams, and result shape.
---

# Core Functions in AI SDK 7

Use `generateText` for non-streaming work and `streamText` for incremental
output. Prefer the text functions plus `output` for new structured-output work.

## Basic Generation

```ts
import { generateText } from 'ai';

const result = await generateText({
  model: __MODEL__,
  instructions: 'Answer as a senior TypeScript engineer.',
  prompt: 'Review this API design.',
});

console.log(result.text);
```

Use top-level `instructions`; `system` is a deprecated fallback in AI SDK 7 and
system messages in `messages` are rejected by default. Use
`allowSystemInMessages: true` only for trusted persisted messages.

## Streaming

```ts
import { streamText } from 'ai';

const result = streamText({
  model: __MODEL__,
  instructions: 'Be concise.',
  prompt: 'Explain the migration plan.',
});

for await (const part of result.stream) {
  if (part.type === 'text-delta') {
    process.stdout.write(part.text);
  }
}
```

`StreamTextResult.fullStream` was renamed to `stream`. `onChunk` now receives
all stream parts, so guard on `chunk.type` before assuming text or tool data.

## Structured Output

```ts
import { generateText, Output } from 'ai';
import { z } from 'zod';

const result = await generateText({
  model: __MODEL__,
  output: Output.object({
    schema: z.object({
      sentiment: z.enum(['positive', 'neutral', 'negative']),
      topics: z.array(z.string()),
    }),
  }),
  prompt: 'Analyze this feedback.',
});

console.log(result.output);
```

`experimental_output` was removed; use `output` and `result.output`.

## Reasoning

Use the top-level `reasoning` option for provider-agnostic reasoning effort
when supported by the model:

```ts
const result = await generateText({
  model: __MODEL__,
  reasoning: 'high',
  prompt: 'Solve this multi-step planning problem.',
});
```

When adopting top-level `reasoning`, remove overlapping provider-specific
reasoning settings unless they intentionally take precedence.

## Timeouts

AI SDK 7 supports a timeout number or an object:

```ts
const result = await streamText({
  model: __MODEL__,
  timeout: {
    totalMs: 60_000,
    stepMs: 15_000,
    chunkMs: 5_000,
    toolMs: 10_000,
    tools: {
      weatherMs: 3_000,
    },
  },
  prompt: 'Use the weather tool and summarize the result.',
});
```

Use `chunkMs` for stalled streams and per-tool overrides for tools with known
latency profiles.

## Result Shape Changes

AI SDK 7 top-level result fields now aggregate across all steps:

- `usage`
- `content`
- `toolCalls`
- `toolResults`
- `files`
- `sources`
- `warnings`

Use `finalStep` for previous final-step-only behavior:

```ts
const result = await generateText({ model: __MODEL__, prompt, stopWhen });

console.log(result.usage); // all steps
console.log(result.finalStep.usage); // final step only
```

For `streamText`, await `result.finalStep` first.

Top-level `reasoning`, `reasoningText`, `request`, `response`, and
`providerMetadata` are deprecated final-step aliases. Read them from
`result.finalStep`.

## Stateless Stream Helpers

Result helper methods are deprecated. Use top-level stateless helpers:

```ts
import {
  createUIMessageStreamResponse,
  streamText,
  toUIMessageStream,
} from 'ai';

const result = streamText({ model: __MODEL__, prompt });
const uiStream = toUIMessageStream({
  stream: result.stream,
  originalMessages,
});

return createUIMessageStreamResponse({ stream: uiStream });
```

Use the matching text-stream helpers for plain text responses:
`toTextStream`, `createTextStreamResponse`, and
`pipeTextStreamToResponse`.

## Lifecycle Renames

Use current v7 names for core functions and `ToolLoopAgent`:

- `experimental_onStart` -> `onStart`
- `experimental_onStepStart` -> `onStepStart`
- `onFinish` -> `onEnd`
- `onStepFinish` -> `onStepEnd`
- `experimental_telemetry` -> `telemetry`
- `experimental_include` -> `include`
- `includeRawChunks` -> `include.rawChunks`
- `experimental_context` -> `context` inside tool callbacks

## Content Parts

Update exhaustive switches, validators, and renderers:

- Tool result `{ type: 'media' }` was removed; use `{ type: 'file-data' }`.
- Prefer canonical `{ type: 'file', mediaType, data: ... }` for file and image
  parts.
- User message `{ type: 'image', image }` is deprecated; use a file part with
  image media type.
- Handle `reasoning-file` content parts where model reasoning can contain
  files.

## Gotchas

- Do not manually JSON-parse model text when `Output` can enforce the shape.
- Do not assume `usage` is final-step usage.
- Do not assume stream parts are only text deltas.
- Do not use deprecated result response helper methods in new v7 code.
