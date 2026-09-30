---
title: Migrate AI SDK v6 to v7
description: Checklist for upgrading AI SDK 6 applications to AI SDK 7.
---

# Migrate AI SDK 6 to 7

The complete checklist is the official guide, installed with v7 at
`node_modules/ai/docs/08-migration-guides/23-migration-guide-7-0.mdx` (web:
[migration guide](https://ai-sdk.dev/docs/migration-guides/migration-guide-7-0)).
Vercel also publishes it as an agent skill:
`npx skills add vercel/ai --skill migrate-ai-sdk-v6-to-v7`.

Keep a recoverable baseline, upgrade compatible packages, run
`npx @ai-sdk/codemod v7` (`bunx --bun @ai-sdk/codemod v7` in a Bun project),
then review the diff. Codemods rename symbols; the rows below are mostly
semantic and need manual review.

## Changes that need deliberate review

| Area | Migration contract |
| --- | --- |
| Runtime | Node.js 22+, ESM-only AI SDK packages (`require()` fails) |
| Prompt/loop | Text `system` → `instructions`; `stepCountIs` → `isStepCount` |
| Step preparation | Returned instructions and messages carry into later steps |
| Trusted history | System messages rejected by default; move server instructions out |
| Core lifecycle | `onFinish` → `onEnd`, `onStepFinish` → `onStepEnd`; client `useChat` callbacks are separate |
| Streaming | `fullStream` → `stream`; `onChunk` sees all parts |
| Results | Top-level usage/content/tool arrays aggregate (`totalUsage` → `usage`); `finalStep` for final-step access; `step.response.messages` is per step, use `result.responseMessages` |
| Context | `experimental_context` → tool `context`; shared `runtimeContext`; per-tool `toolsContext` + `contextSchema` |
| Approval | Tool `needsApproval` deprecated (no type error, no codemod) → call/agent `toolApproval`; WorkflowAgent still uses `needsApproval` |
| Output | Removed `experimental_output`; prefer `Output` on text functions |
| Responses | `result.toUIMessageStreamResponse()` etc. deprecated → `createUIMessageStreamResponse({ stream: toUIMessageStream({ stream: result.stream }) })`, `toTextStream` + `createTextStreamResponse` |
| Bodies | `request.body`/`response.body` are empty unless `include: { requestBody, responseBody }` |
| Telemetry | Install `@ai-sdk/otel`, `registerTelemetry(new OpenTelemetry())` at startup; `experimental_telemetry` → `telemetry`; on by default once registered |
| DevTools | `devToolsMiddleware()` → `registerTelemetry(DevToolsTelemetry())`, `@ai-sdk/devtools@latest` |
| Reasoning | Provider settings override overlapping top-level `reasoning` |
| Files | Canonical `file` parts, `file-data` tool output, `reasoning-file` handling |
| MCP | HTTP/SSE `redirect` defaults to `'error'`; set `'follow'` only for trusted servers |
| Providers | OpenAI Responses `reasoningSummary` defaults to `'detailed'` when reasoning is on (`null` disables); `xai(id)` uses the Responses API (`xai.chat(id)` for chat); Anthropic `cacheCreationInputTokens` → `usage.inputTokenDetails.cacheWriteTokens`; Google `GoogleGenerativeAI*` → `Google*` |

Search the migration guide for remaining removed/renamed symbols. An alias
being deprecated does not mean it is already removed; migrate in the documented
scope instead of global textual replacement.

Run typecheck and relevant integration tests. Exercise multi-step tools, manual
denial, restored history and streaming failure when those paths changed.
