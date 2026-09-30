---
name: ai-sdk-7
description: "Vercel AI SDK v7 development and migration. Use when building or upgrading AI SDK 7 apps, especially ToolLoopAgent, WorkflowAgent, HarnessAgent, Claude Code/Codex/Pi harnesses, runtimeContext, toolsContext, toolApproval, telemetry, reasoning, file or skill uploads, realtime, video generation, or v6-to-v7 breaking changes. For AI SDK v6 code use ai-sdk-6; for version discovery and general doc lookup use ai-sdk."
compatibility: "TypeScript/JavaScript projects using AI SDK 7; Node.js >=22; AI SDK packages are ESM-only."
---

# AI SDK 7 implementation and migration

Apply this skill to `ai@7`; use `ai-sdk` to resolve unknown versions and
`ai-sdk-6` for v6 maintenance. Match provider and UI package versions to the
project. AI SDK 7 requires Node.js 22+ and AI SDK packages are ESM-only.

Read `node_modules/ai/docs/` first: `03-agents/`, `03-ai-sdk-core/`,
`03-ai-sdk-harnesses/`, `04-ai-sdk-ui/`, `08-migration-guides/`. `@ai-sdk/react`,
`workflow`, `harness`, `otel` and `mcp` ship types/src only; their guides are
there. Provider options: `node_modules/@ai-sdk/<provider>/docs/`. Web fallback:
the [official docs](https://ai-sdk.dev/docs). Experimental package APIs need a
fresh check before adding long-lived wrappers.

## Important boundaries

- Text functions and ToolLoopAgent use `instructions`; loop limits use
  `isStepCount`. Defaults: text functions 1 step (tools run, no follow-up
  text), ToolLoopAgent 20, WorkflowAgent unbounded. Check callback scope before
  renaming core `onFinish` to `onEnd`; React `useChat.onFinish` is separate.
- `prepareStep` instruction/message overrides carry forward. Results such as
  `usage` and tool arrays aggregate all steps; `finalStep` preserves final-step
  access, and is awaited for streams. `step.response.messages` holds only that
  step's messages; persist `result.responseMessages`.
- Use `runtimeContext` for server loop state and schema-validated
  `toolsContext` for per-tool state. Neither is model-visible merely by being
  context.
- Default to `ToolLoopAgent` (`ai`). Use `WorkflowAgent` (`@ai-sdk/workflow`)
  only when a run must survive restarts or wait on approval, and `HarnessAgent`
  (`@ai-sdk/harness/agent`) to drive Claude Code, Codex, Pi and similar
  runtimes. Approval and persistence APIs differ across the three.
- Resolve model IDs and capabilities from the configured provider. Avoid
  overlapping reasoning settings: provider options can override top-level
  `reasoning`.

## Read for the feature

- [Agents](references/agents.md): in-memory/durable execution and context.
- [Harnesses](references/harnesses.md): runtime-owned sessions and permissions.
- [Core functions](references/core-functions.md): output, stream and result contracts.
- [Tools](references/tools.md): approval boundaries, MCP Apps and sandbox handles.
- [UI hooks](references/ui-hooks.md): UI streams, approval and resumption.
- [Migration](references/migration-v6-to-v7.md): semantic changes and codemods.
- [Telemetry](references/telemetry.md): registration and data controls.
- [Media/files](references/media-and-files.md): provider references and capability gates.
- [Examples](references/examples.md): current official implementations.

Typecheck and exercise the changed multi-turn, tool, stream or resume path.
A successful compile does not prove approval policy or persistence behavior.
