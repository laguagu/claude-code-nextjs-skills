---
title: Migrate AI SDK v6 to v7
description: Checklist for upgrading AI SDK 6 applications to AI SDK 7.
---

# Migrate AI SDK v6 to v7

Use this file as the working checklist. When behavior is unclear, read the
official migration guide or the installed `node_modules/ai/docs/` copy.

## Workflow

1. Ensure the project has a committed baseline or other clean backup.
2. Inspect `package.json`, lockfiles, and installed `ai` / `@ai-sdk/*` versions.
3. Upgrade the AI SDK packages used by the project.
4. Run codemods from the project root:

```bash
npx @ai-sdk/codemod v7
```

5. Apply the manual checks below only where matching code exists.
6. Run typecheck, targeted tests, and a streaming/tool smoke test if those paths
   changed.

Prefer behavior-preserving changes. When v7 changes semantics, decide whether
the app wants the new all-steps behavior or the previous final-step-only
behavior.

## Runtime and Modules

- Node.js must be >=22.
- AI SDK packages are ESM-only.
- Replace `require()` with ESM imports.
- Add `"type": "module"` or use `.mjs` where needed.

## Core Renames

- `experimental_customProvider` -> `customProvider`
- `experimental_generateImage` -> `generateImage`
- `experimental_transcribe` -> `transcribe`
- `experimental_generateSpeech` -> `generateSpeech`
- `experimental_output` option/result -> `output`
- `CallSettings` -> `LanguageModelCallOptions & Omit<RequestOptions, 'timeout'>`
- `prepareCallSettings` -> `prepareLanguageModelCallOptions`
- `stepCountIs` -> `isStepCount`

## Prompts and Steps

- Top-level `system` -> `instructions`.
- Move `{ role: 'system' }` messages into top-level `instructions`.
- Use `allowSystemInMessages: true` only for trusted persisted messages.
- `experimental_prepareStep` -> `prepareStep`.
- Returned `system` from `prepareStep` -> `instructions`.
- In `experimental_repairToolCall`, use `{ instructions }` instead of
  `{ system }`.
- Audit `prepareStep`: returned `instructions` and `messages` now carry forward
  into later steps.

## Lifecycle and Telemetry

- `experimental_onStart` -> `onStart`
- `experimental_onStepStart` -> `onStepStart`
- `onFinish` -> `onEnd`
- `onStepFinish` -> `onStepEnd`
- `experimental_onFinish` -> `onEnd` for `embed`, `embedMany`, and `rerank`
- `experimental_telemetry` -> `telemetry`
- OpenTelemetry moved to `@ai-sdk/otel`; register once at app startup with
  `registerTelemetry(new OpenTelemetry())`.
- Telemetry is enabled by default after registration. Use
  `telemetry: { isEnabled: false }` to opt out per call.
- `experimental_include` -> `include`
- `includeRawChunks` -> `include.rawChunks`
- Request/response bodies are excluded by default; opt in with
  `include.requestBody` and `include.responseBody` when code reads them.

## Streaming and Tools

- `StreamTextResult.fullStream` -> `stream`.
- `streamText` `onChunk` now receives all stream parts; guard by `chunk.type`.
- `step.response.messages` is no longer accumulated across previous steps. Use
  `result.responseMessages` or flatten `result.steps`.
- `experimental_onToolCallStart` -> `onToolExecutionStart`
- `experimental_onToolCallFinish` -> `onToolExecutionEnd`
- Tool callback `experimental_context` -> `context`
- Split shared data into `runtimeContext` and per-tool data into
  `toolsContext` plus tool `contextSchema`.
- Move `needsApproval` from `tool()` / `dynamicTool()` to per-call or agent
  `toolApproval`, except for `WorkflowAgent`, which still uses tool-level
  `needsApproval`.
- `experimental_activeTools` -> `activeTools`
- `ToolCallOptions` -> `ToolExecutionOptions`
- `isToolOrDynamicToolUIPart` -> `isToolUIPart`

## Content Parts

- Tool result `{ type: 'media' }` is removed; use `{ type: 'file-data' }`.
- Migrate image/file output variants to canonical `{ type: 'file', mediaType,
  data: { type: 'data' | 'url' | 'reference', ... } }`.
- User message `{ type: 'image', image }` is deprecated; use a file part with
  image media type.
- Add `reasoning-file` to exhaustive switches, serializers, and renderers.

## Multi-Step Result Shape

- `result.usage` now includes all steps. `result.totalUsage` is deprecated.
- Use `result.finalStep.usage` for final-step-only usage.
- Top-level `content`, `toolCalls`, `toolResults`, `files`, `sources`, and
  `warnings` now include all steps.
- Top-level `reasoning`, `reasoningText`, `request`, `response`, and
  `providerMetadata` are deprecated final-step aliases; use `result.finalStep`.
- For `streamText`, await `result.finalStep`.

## Stream Response Helpers

Replace result methods with stateless helpers:

- `result.toUIMessageStream(...)` -> `toUIMessageStream({ stream: result.stream, ... })`
- `result.toUIMessageStreamResponse(...)` -> `toUIMessageStream(...)` plus `createUIMessageStreamResponse({ stream })`
- `result.pipeUIMessageStreamToResponse(...)` -> `toUIMessageStream(...)` plus `pipeUIMessageStreamToResponse(...)`
- `result.toTextStreamResponse()` -> `toTextStream({ stream: result.stream })` plus `createTextStreamResponse({ stream })`
- `result.pipeTextStreamToResponse(...)` -> `toTextStream(...)` plus `pipeTextStreamToResponse(...)`

## Package Checks

- MCP HTTP/SSE transport `redirect` now defaults to `'error'`; set
  `redirect: 'follow'` only for trusted MCP servers that need redirects.
- `@ai-sdk/vue` `Chat` class is deprecated; prefer `useChat`.
- Anthropic cache creation tokens moved to
  `usage.inputTokenDetails.cacheWriteTokens`; raw Anthropic usage remains in
  `finalStep.providerMetadata`.
- Google provider names dropped `GenerativeAI` from type/class/function names;
  the `google` entry point remains unchanged.

## Validation

- Run the package manager's typecheck.
- Run the smallest relevant unit/integration tests.
- Smoke-test streaming, chat UI, tool execution, telemetry, and multi-step flows
  when those areas changed.
- If type errors remain, search the official migration guide for the exact
  removed or renamed symbol before inventing a workaround.
