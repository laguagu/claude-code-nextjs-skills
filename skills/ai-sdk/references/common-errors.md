---
title: Common Errors
description: Reference for common AI SDK errors and how to resolve them.
---

# Common API mismatches

Check the installed major before changing a failing symbol. Use its package
docs/types and the [official migration guides](https://ai-sdk.dev/docs/migration-guides).

| Old pattern | Current contract |
| --- | --- |
| `maxTokens`, `maxSteps` | `maxOutputTokens`, `stopWhen`; v6 helper `stepCountIs`, v7 `isStepCount` |
| Tool `parameters` | `inputSchema` |
| `generateObject` / `streamObject`, manual JSON parsing | Deprecated; text functions with `output: Output.object/array/choice/json(...)` |
| `useChat` `input`, `handleInputChange`, `handleSubmit`, `api` | Own `useState` input, `sendMessage({ text })`, `transport: new DefaultChatTransport({ api })` |
| `tool-invocation`, `part.toolInvocation.args/result/toolCallId` | Typed `tool-{name}` or `dynamic-tool` parts with `part.input`, `part.output`, `part.toolCallId` |
| v5 `isToolUIPart` / `getToolName` (static only) | v6+ `isStaticToolUIPart` / `getStaticToolName`; `isToolUIPart` / `getToolName` include dynamic tools |
| Tool states `partial-call`, `call`, `result` | `input-streaming`, `input-available`, `output-available` (plus approval/denied/error states) |
| `addToolResult({ toolCallId, result })` | `addToolOutput({ tool, toolCallId, output })` |
| `toDataStreamResponse()` for `useChat` | v6 `toUIMessageStreamResponse()`; v7 `toUIMessageStream` + `createUIMessageStreamResponse` |
| `convertToCoreMessages`, `CoreMessage` | `convertToModelMessages` (async since v6, await it), `ModelMessage` |
| `messages` on `createAgentUIStreamResponse` | `uiMessages` |

Tools executing without a final answer can be the default one-step limit of
`generateText`/`streamText`. Set `stopWhen` for a follow-up model step;
`ToolLoopAgent` defaults to 20 steps.

Narrow a tool part by type **and state** before reading input/output; streaming
input is partial, errors and denial have different shapes. Do not solve these
errors by casting away the union.

For `useChat`, return the UI-message protocol, not an arbitrary text or legacy
data stream. SDK 6 has result response helpers; SDK 7 favors stateless helpers.
Client `useChat.onFinish` and core generation completion callbacks are separate
APIs. Apply renames only in the documented scope.

For v7 renames (`system` → `instructions`, `fullStream` → `stream`, core
`onFinish` → `onEnd`, ...) and semantic changes, read
[migration-v6-to-v7.md](../../ai-sdk-7/references/migration-v6-to-v7.md).
Deprecated aliases may still work; deprecation is not the same as removal.
