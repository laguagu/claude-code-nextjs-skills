---
title: Migrate AI SDK v6 to v7
description: Checklist for upgrading AI SDK 6 applications to AI SDK 7.
---

# Migrate AI SDK 6 to 7

Use the [official migration guide](https://ai-sdk.dev/docs/migration-guides/migration-guide-7-0)
as the complete checklist. A v6 install does not contain it; after upgrading
`ai` it is at `node_modules/ai/docs/08-migration-guides/23-migration-guide-7-0.mdx`.
Vercel also publishes a migration skill
(`npx skills add vercel/ai --skill migrate-ai-sdk-v6-to-v7`). Keep a recoverable
baseline, upgrade compatible packages, run the v7 codemod with the project's
runner (`bunx --bun @ai-sdk/codemod v7` in a Bun project), then review the diff.
Codemods do not cover every semantic change.

## Renames to search for

- Core: `system` → `instructions` (also `prepareStep` and repair-call returns),
  `stepCountIs` → `isStepCount`, `experimental_output` → `output`,
  `experimental_prepareStep` → `prepareStep`, `experimental_activeTools` →
  `activeTools`, `experimental_customProvider`/`_generateImage`/`_transcribe`/
  `_generateSpeech` → unprefixed, `CallSettings` →
  `LanguageModelCallOptions & Omit<RequestOptions, 'timeout'>`.
- Callbacks: `onFinish` → `onEnd`, `onStepFinish` → `onStepEnd`,
  `experimental_onStart`/`_onStepStart` → `onStart`/`onStepStart`,
  `experimental_onToolCallStart`/`_onToolCallFinish` →
  `onToolExecutionStart`/`onToolExecutionEnd`, embed/rerank
  `experimental_onFinish` → `onEnd`.
- Telemetry/streams: `experimental_telemetry` → `telemetry` (tracer moves into
  `new OpenTelemetry({ tracer })`), `experimental_include` → `include`,
  `includeRawChunks` → `include.rawChunks`, `fullStream` → `stream`.
- Tools/types: tool callback `experimental_context` → `context` (values via
  `toolsContext`), top-level `experimental_context` → `runtimeContext` (split
  per-tool data into `toolsContext`), `ToolCallOptions` →
  `ToolExecutionOptions`, `isToolOrDynamicToolUIPart` → `isToolUIPart`
  (already the preferred static-or-dynamic predicate in v6),
  `needsApproval: true` → `toolApproval: { name: 'user-approval' }`.
- Usage/results: `totalUsage` → `usage` (now all steps; `finalStep.usage` is the
  old `usage`), `usage.cachedInputTokens` → `usage.inputTokenDetails.cacheReadTokens`,
  `usage.reasoningTokens` → `usage.outputTokenDetails.reasoningTokens`;
  `step.response.messages` is per step, use `result.responseMessages` for all.
- Response helpers: `result.toUIMessageStreamResponse(opts)` →
  `createUIMessageStreamResponse({ stream: toUIMessageStream({ stream: result.stream, ...opts }) })`;
  likewise `pipeUIMessageStreamToResponse`, `toTextStream` +
  `createTextStreamResponse`/`pipeTextStreamToResponse`.
- Content parts: tool-result `media` → `file-data`; `image-*`/`file-*` result
  variants and user `image` parts → `file` parts with `mediaType`.
- Providers: Anthropic `cacheCreationInputTokens` metadata →
  `usage.inputTokenDetails.cacheWriteTokens`; Google `GoogleGenerativeAI*`
  names → `Google*`; `xai(id)` uses the Responses API (`xai.chat(id)` keeps Chat
  Completions); OpenAI Responses with reasoning defaults `reasoningSummary` to
  `'detailed'` (`null` disables).

## Changes that need deliberate review

| Area | Migration contract |
| --- | --- |
| Runtime | Node.js 22+, ESM-only AI SDK packages; `require()` is officially unsupported, though it may load through require(esm) on Node ≥22.12 |
| Step preparation | Returned instructions and messages carry into later steps |
| Trusted history | System messages in `messages`/`prompt` rejected by default; `allowSystemInMessages` only for trusted stored history |
| Callbacks | Rename core/agent/UI-stream callbacks only; client `useChat` `onFinish` keeps its name |
| Streaming | `onChunk` sees all parts, not only text/tool deltas |
| Results | Top-level usage/content/tool arrays aggregate; use `finalStep` for final-step access |
| Context | Shared `runtimeContext`; per-tool `toolsContext` + `contextSchema` |
| Approval | Core/ToolLoopAgent `toolApproval`; WorkflowAgent still uses `needsApproval` |
| Telemetry | Startup registration; enabled once registered; bodies and context excluded unless included |
| Reasoning | Provider settings override overlapping top-level `reasoning` |
| Files | Canonical `file` parts, `file-data` tool output, `reasoning-file` handling |
| MCP | HTTP/SSE `redirect` defaults to `'error'`; `'follow'` only for trusted servers |

Search the migration guide for remaining removed/renamed symbols. An alias
being deprecated does not mean it is already removed; migrate in the documented
scope instead of global textual replacement.

Audit replay/serialization, usage accounting and approval policies separately
from type errors. Verify request/response body inclusion if integrations inspect
those fields. Consult only the package sections the app uses.

Run typecheck and relevant integration tests. Exercise multi-step tools, manual
denial, restored history and streaming failure when those paths changed.
