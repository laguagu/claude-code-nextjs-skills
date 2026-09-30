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
| Manual JSON parsing for schema output | Text generation with `output: Output.object(...)`, when supported |
| `useChat` input/submit handlers and `api` option | Controlled form input, `sendMessage`, transport configuration |
| `tool-invocation`, `args`, `result` | Typed `tool-{name}` or dynamic parts, `input`, `output` |
| `addToolResult` | `addToolOutput` with the installed signature |
| `messages` on `createAgentUIStreamResponse` | `uiMessages` |

Narrow a tool part by type **and state** before reading input/output; streaming
input is partial, errors and denial have different shapes. Do not solve these
errors by casting away the union.

For `useChat`, return the UI-message protocol, not an arbitrary text or legacy
data stream. SDK 6 has result response helpers; SDK 7 favors stateless helpers.
Client `useChat.onFinish` and core generation completion callbacks are separate
APIs. Apply renames only in the documented scope.

For v7 semantic changes, read
[migration-v6-to-v7.md](../../ai-sdk-7/references/migration-v6-to-v7.md).
Deprecated aliases may still work; deprecation is not the same as removal.
