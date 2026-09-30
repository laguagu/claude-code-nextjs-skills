---
title: Common Errors
description: Reference for common AI SDK errors and how to resolve them.
---

# Common API mismatches

Check the installed major before changing a failing symbol. Use its package
docs/types and the migration guides in `node_modules/ai/docs/08-migration-guides/`
(or the [official migration guides](https://ai-sdk.dev/docs/migration-guides)).

| Old pattern | Current contract |
| --- | --- |
| `maxTokens`, `maxSteps` | `maxOutputTokens`, `stopWhen`; v6 helper `stepCountIs`, v7 `isStepCount` |
| Tool `parameters` | `inputSchema` |
| `generateObject`/`streamObject`, manual JSON parsing | Text function with `output: Output.object({ schema })`; read `result.output` |
| `convertToCoreMessages`, `CoreMessage` | `await convertToModelMessages(...)` (async since v6), `ModelMessage` |
| `Experimental_Agent` with `system` | `ToolLoopAgent` with `instructions` (v6+) |
| `useChat` input/submit handlers and `api` option | Controlled form input, `sendMessage({ text })`, `transport: new DefaultChatTransport({ api })` |
| `tool-invocation`, `args`, `result` | Typed `tool-{name}` or dynamic parts, `input`, `output` |
| v5 `isToolUIPart` / `getToolName` (static only) | v6+ `isStaticToolUIPart` / `getStaticToolName`; `isToolUIPart` / `getToolName` now include dynamic tools |
| `addToolResult` | `addToolOutput` (alias deprecated) |
| `messages` on `createAgentUIStreamResponse` | `uiMessages` |
| `toDataStreamResponse()` for `useChat` | v6 `result.toUIMessageStreamResponse()`; v7 `createUIMessageStreamResponse({ stream: toUIMessageStream({ stream: result.stream }) })` |

- Tools run but no final answer: `generateText`/`streamText` default to one
  step (`stopWhen` step count 1); set `stopWhen`. `ToolLoopAgent` defaults to 20.
- Narrow a tool part by type **and state** before reading input/output;
  streaming input is partial, errors and denial have different shapes. Do not
  cast away the union.
- Client `useChat.onFinish` and server completion callbacks are separate APIs:
  v7 renames the server ones (core, agents, UI-stream helpers) to `onEnd`;
  `useChat` keeps `onFinish`.

For v7 semantic changes, read
[migration-v6-to-v7.md](../../ai-sdk-7/references/migration-v6-to-v7.md).
Deprecated aliases may still work; deprecation is not the same as removal.
