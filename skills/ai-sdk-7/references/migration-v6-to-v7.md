---
title: Migrate AI SDK v6 to v7
description: Checklist for upgrading AI SDK 6 applications to AI SDK 7.
---

# Migrate AI SDK 6 to 7

Use the [official migration guide](https://ai-sdk.dev/docs/migration-guides/migration-guide-7-0)
and its installed copy as the complete checklist. Keep a recoverable baseline,
upgrade compatible packages, run the v7 codemod with the project's runner
(`bunx --bun @ai-sdk/codemod v7` in a Bun project), then review the diff.
Codemods do not cover every semantic change.

## Changes that need deliberate review

| Area | Migration contract |
| --- | --- |
| Runtime | Node.js 22+, ESM-only AI SDK packages |
| Prompt/loop | Text `system` → `instructions`; `stepCountIs` → `isStepCount` |
| Step preparation | Returned instructions and messages carry into later steps |
| Trusted history | System messages rejected by default; move server instructions out |
| Core lifecycle | `onFinish` → `onEnd`, `onStepFinish` → `onStepEnd`; client `useChat` callbacks are separate |
| Streaming | `fullStream` → `stream`; `onChunk` sees all parts |
| Results | Top-level usage/content/tool arrays aggregate; use `finalStep` for final-step access |
| Context | Shared `runtimeContext`; per-tool `toolsContext` + `contextSchema` |
| Approval | Core/ToolLoopAgent `toolApproval`; WorkflowAgent still uses `needsApproval` |
| Output | Removed `experimental_output`; prefer `Output` on text functions |
| Responses | Prefer stateless UI/text helpers over deprecated result methods |
| Telemetry | `telemetry`, startup registration, explicit body/context inclusion |
| Reasoning | Provider settings override overlapping top-level `reasoning` |
| Files | Canonical `file` parts, `file-data` tool output, `reasoning-file` handling |

Search the migration guide for remaining removed/renamed symbols. An alias
being deprecated does not mean it is already removed; migrate in the documented
scope instead of global textual replacement.

Audit replay/serialization, usage accounting and approval policies separately
from type errors. Verify request/response body inclusion if integrations inspect
those fields. MCP redirect defaults and provider token/metadata fields can also
change; consult only the package sections the app uses.

Run typecheck and relevant integration tests. Exercise multi-step tools, manual
denial, restored history and streaming failure when those paths changed.
