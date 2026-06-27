---
name: ai-sdk-7
description: "Vercel AI SDK v7 development and migration. Use when building or upgrading AI SDK 7 apps, especially ToolLoopAgent, WorkflowAgent, HarnessAgent, Claude Code/Codex/Pi harnesses, runtimeContext, toolsContext, toolApproval, telemetry, reasoning, file or skill uploads, realtime, video generation, or v6-to-v7 breaking changes. For AI SDK v6 code use ai-sdk-6; for version discovery and general doc lookup use ai-sdk."
argument-hint: "[question or feature]"
compatibility: "TypeScript/JavaScript projects using AI SDK 7; Node.js >=22; AI SDK packages are ESM-only."
---

# Vercel AI SDK v7 Development Guide

Use this skill for AI SDK 7-specific implementation, migrations, and agent
architecture. For AI SDK 6 projects, use `ai-sdk-6`. For unknown versions, use
`ai-sdk` first to inspect `node_modules/ai/package.json` and local docs.

## First Checks

1. Inspect `package.json`, lockfiles, and `node_modules/ai/package.json`.
2. Confirm the installed `ai` major version is 7 before applying this guide.
3. Search local docs first: `node_modules/ai/docs/` and `node_modules/ai/src/`.
4. In monorepos, check app/package workspaces such as `apps/*/node_modules/ai/`
   and `packages/*/node_modules/ai/`.
5. If local docs are missing or ambiguous, verify against `ai-sdk.dev` or the
   Vercel AI repository docs source before coding.

AI SDK 7 requires Node.js >=22 and AI SDK packages are ESM-only. Convert
`require()` imports to `import` syntax before chasing downstream type errors.

## Install

Use the project's package manager and install only packages needed by the task:

```bash
bun add ai @ai-sdk/react
bun add @ai-sdk/openai # or the provider already used by the project
```

For durable agents, add `@ai-sdk/workflow` and `workflow`. For harness agents,
add `@ai-sdk/harness`, one harness adapter, and a sandbox provider.

## Core v7 Patterns

| Task | Prefer in AI SDK 7 |
| --- | --- |
| Text generation | `generateText` / `streamText` |
| System prompt | top-level `instructions`, not `system` |
| Structured output | `output: Output.object(...)` on text functions |
| Loop limit | `stopWhen: isStepCount(n)` |
| Shared server state | `runtimeContext` |
| Per-tool state/secrets | tool `contextSchema` + `toolsContext` |
| Sensitive tools | `toolApproval` on `generateText`, `streamText`, or `ToolLoopAgent` |
| Durable long-running agents | `WorkflowAgent` from `@ai-sdk/workflow` |
| Running Claude Code/Codex/Pi | `HarnessAgent` from `@ai-sdk/harness/agent` |
| Observability | `registerTelemetry(new OpenTelemetry())` |
| Stalled calls | `timeout` number or object |

In examples, `__MODEL__` is a placeholder: resolve a current model via the
project's provider package (e.g. `anthropic('...')`) or a gateway model string,
following the model-ID guidance in the `ai-sdk` skill. Never hard-code a model
ID from memory.

```ts
import { generateText, isStepCount, Output } from 'ai';
import { z } from 'zod';

const result = await generateText({
  model: __MODEL__,
  instructions: 'Answer concisely.',
  prompt: 'Classify this support ticket.',
  reasoning: 'high',
  stopWhen: isStepCount(3),
  timeout: { totalMs: 60_000, stepMs: 15_000 },
  output: Output.object({
    schema: z.object({
      priority: z.enum(['low', 'medium', 'high']),
      summary: z.string(),
    }),
  }),
});

console.log(result.output);
```

## Documentation Routing

Read only the reference needed for the current task:

- [agents.md](references/agents.md) - `ToolLoopAgent`, `WorkflowAgent`, context, approvals.
- [harnesses.md](references/harnesses.md) - `HarnessAgent`, sessions, adapters, sandboxing, UI.
- [core-functions.md](references/core-functions.md) - `generateText`, `streamText`, output, result shape.
- [tools.md](references/tools.md) - tools, context, approvals, MCP Apps, sandbox handles.
- [ui-hooks.md](references/ui-hooks.md) - `useChat`, typed tool parts, approvals, harness/workflow UI.
- [migration-v6-to-v7.md](references/migration-v6-to-v7.md) - codemod and breaking-change checklist.
- [telemetry.md](references/telemetry.md) - OpenTelemetry, tracing channel, lifecycle telemetry.
- [media-and-files.md](references/media-and-files.md) - `uploadFile`, `uploadSkill`, realtime, video.
- [examples.md](references/examples.md) - how to fetch canonical examples from `vercel/ai`.

## Gotchas

- Do not rely on memory for AI SDK APIs. Verify against local docs/source or
  official docs before writing code.
- Harness packages are experimental. Keep adapter/package details easy to change
  and re-check docs before adding long-lived abstractions.
- `result.usage` now aggregates all steps. Use `result.finalStep.usage` for
  previous final-step-only behavior.
- For `streamText`, await `result.finalStep` before reading final-step-only
  metadata.
- Harness sessions own conversation history. Persist resume state from
  `detach()` or `stop()` instead of replaying the entire UI message history.
- `WorkflowAgent` is stream-first and durable; use `ToolLoopAgent` for simple
  in-memory agents.
- `toolApproval` applies to AI SDK-executed tools. Provider-executed tools and
  harness built-ins have separate approval/permission behavior.
- Always fetch or verify current model IDs from the project's config or provider
  docs before hard-coding a model string.
