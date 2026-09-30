---
name: ai-sdk-7
description: "Vercel AI SDK v7 development and migration. Use when building or upgrading AI SDK 7 apps, especially ToolLoopAgent, WorkflowAgent, HarnessAgent, Claude Code/Codex/Pi harnesses, runtimeContext, toolsContext, toolApproval, telemetry, reasoning, file or skill uploads, realtime, video generation, or v6-to-v7 breaking changes. For AI SDK v6 code use ai-sdk-6; for version discovery and general doc lookup use ai-sdk."
compatibility: "TypeScript/JavaScript projects using AI SDK 7; Node.js >=22; AI SDK packages are ESM-only."
---

# AI SDK 7 implementation and migration

Apply this skill to `ai@7`; use `ai-sdk` to resolve unknown versions and
`ai-sdk-6` for v6 maintenance. Match provider and UI package versions to the
project. AI SDK 7 requires Node.js 22+ and AI SDK packages are ESM-only.

Read the resolved `ai/docs/`, provider docs and installed source/types first.
Use [official docs](https://ai-sdk.dev/docs) or the matching repository tag
when local docs are unavailable. Experimental package APIs need a fresh check
before adding long-lived wrappers.

## Important boundaries

- Text functions and ToolLoopAgent use `instructions`; loop limits use
  `isStepCount`. Check callback scope before renaming core `onFinish` to
  `onEnd`; React `useChat.onFinish` is separate.
- `prepareStep` instruction/message overrides carry forward. Results such as
  `usage` and tool arrays aggregate all steps; `finalStep` preserves final-step
  access, and is awaited for streams.
- Use `runtimeContext` for server loop state and schema-validated
  `toolsContext` for per-tool state. Neither is model-visible merely by being
  context.
- Approval, persistence and lifecycle differ across ToolLoopAgent,
  WorkflowAgent, HarnessAgent and provider-executed tools. Choose the runtime
  for the actual durability/permission requirements.
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
