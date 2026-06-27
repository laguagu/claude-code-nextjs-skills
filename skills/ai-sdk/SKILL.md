---
name: ai-sdk
description: 'Answer questions about the AI SDK and help build AI-powered features. Use when developers ask about Vercel AI SDK, generateText, streamText, ToolLoopAgent, useChat, providers, tools, structured output, embeddings, streaming, or adding AI to an app. First identify the installed major version and route version-specific work: use ai-sdk-7 for AI SDK 7 features/migrations such as WorkflowAgent, HarnessAgent, reasoning, runtime/tools context, toolApproval, telemetry, realtime, or v6-to-v7 upgrades; use ai-sdk-6 for v6 code.'
argument-hint: "[question or feature]"
---

## Prerequisites

Before searching docs, check the installed major version in `package.json`,
lockfiles, or `node_modules/ai/package.json`.

- AI SDK 7 implementation or migration work -> use `ai-sdk-7`.
- AI SDK 6 implementation work -> use `ai-sdk-6`.
- Unknown or mixed versions -> continue with this skill until the version is
  clear. If starting fresh or no version is pinned, assume the current line
  (AI SDK 7) and use `ai-sdk-7`.

Before searching docs, check if `node_modules/ai/docs/` exists. If not, install
**only** the `ai` package using the project's package manager (e.g., `bun add ai`).

Do not install other packages at this stage. Provider packages (e.g., `@ai-sdk/openai`) and client packages (e.g., `@ai-sdk/react`) should be installed later when needed based on user requirements.

### Monorepo path note

In Bun / pnpm / Yarn workspace monorepos, dependencies are usually **not** hoisted to the repo root — they live inside each app's `node_modules/`. If `node_modules/ai/docs/` doesn't exist at the working directory, check workspace locations before assuming docs are missing:

- `apps/*/node_modules/ai/docs/` (e.g. `apps/web/node_modules/ai/docs/`)
- `packages/*/node_modules/ai/docs/`

Glob from the repo root: `apps/*/node_modules/ai/docs/` or `**/node_modules/ai/docs/`. Substitute the resolved path everywhere this skill says `node_modules/ai/docs/` or `node_modules/ai/src/`. The same applies to provider docs at `node_modules/@ai-sdk/<provider>/docs/`.

## Critical: Do Not Trust Internal Knowledge

Everything you know about the AI SDK is outdated or wrong. Your training data contains obsolete APIs, deprecated patterns, and incorrect usage.

**When working with the AI SDK:**

1. Ensure `ai` package is installed (see Prerequisites)
2. Identify the installed major version and use `ai-sdk-7` or `ai-sdk-6` for deep version-specific work
3. Search `node_modules/ai/docs/` and `node_modules/ai/src/` for current APIs
4. If not found locally, search ai-sdk.dev documentation (instructions below)
5. Never rely on memory - always verify against source code or docs
6. **`useChat` has changed significantly** - check [Common Errors](references/common-errors.md) before writing client code
7. **Always fetch current model IDs** - Never use model IDs from memory. A public catalog of current IDs across providers is available at `https://ai-gateway.vercel.sh/v1/models` — useful purely for discovery, not a recommendation to use Gateway as a runtime provider. Example: `curl -s https://ai-gateway.vercel.sh/v1/models | jq -r '[.data[] | select(.id | startswith("anthropic/")) | .id] | reverse | .[]'` (swap `anthropic/` for `openai/`, `google/`, etc.). Use the model with the highest version number (e.g., `claude-sonnet-4-6` over `claude-sonnet-4-5` over `claude-3-5-sonnet`).
8. Run typecheck after changes to ensure code is correct
9. **Be minimal** - Only specify options that differ from defaults. When unsure of defaults, check docs or source rather than guessing or over-specifying.

If you cannot find documentation to support your answer, state that explicitly.

## Finding Documentation

### ai@6.0.34+ and ai@7+

Search bundled docs and source in `node_modules/ai/`:

- **Docs**: `grep "query" node_modules/ai/docs/`
- **Source**: `grep "query" node_modules/ai/src/`

Provider packages include docs at `node_modules/@ai-sdk/<provider>/docs/`.

For v7-specific features such as `WorkflowAgent`, `HarnessAgent`, tool context,
reasoning, telemetry, realtime, video, or v6-to-v7 migration, read the
`ai-sdk-7` skill after confirming the installed major version.

### Earlier versions or missing local docs

1. Search: `https://ai-sdk.dev/api/search-docs?q=your_query`
2. Fetch `.md` URLs from results (e.g., `https://ai-sdk.dev/docs/agents/building-agents.md`)

### Working examples

For runnable provider × feature examples (Anthropic cache-control, OpenAI computer-use, Google grounding, etc.), see [examples.md](references/examples.md). Fetch individual files on demand via WebFetch or `gh api` — do not clone the repo.

## When Typecheck Fails

**Before searching source code**, grep [Common Errors](references/common-errors.md) for the failing property or function name. Many type errors are caused by deprecated APIs documented there.

If not found in common-errors.md:

1. Search `node_modules/ai/src/` and `node_modules/ai/docs/`
2. Search ai-sdk.dev (for earlier versions or if not found locally)

## Building and Consuming Agents

### Creating Agents

Use the agent pattern that matches the installed major version and task:

- v6/v7 in-memory agent loops: `ToolLoopAgent`
- v7 durable workflow-backed agents: `WorkflowAgent` from `@ai-sdk/workflow`
- v7 external coding/runtime harnesses: `HarnessAgent` from `@ai-sdk/harness/agent`

Search `node_modules/ai/docs/` for current agent creation APIs before writing code.

**File conventions**: See [type-safe-agents.md](references/type-safe-agents.md) for where to save agents and tools.

**Type Safety**: When consuming agents with `useChat`, always use `InferAgentUIMessage<typeof agent>` for type-safe tool results. See [reference](references/type-safe-agents.md).

### Consuming Agents (Framework-Specific)

Before implementing agent consumption:

1. Check `package.json` to detect the project's framework/stack
2. Search documentation for the framework's quickstart guide
3. Follow the framework-specific patterns for streaming, API routes, and client integration

## References

- [Common Errors](references/common-errors.md) - Renamed parameters reference (parameters → inputSchema, etc.)
- [Type-Safe Agents with useChat](references/type-safe-agents.md) - End-to-end type safety with InferAgentUIMessage
- [DevTools](references/devtools.md) - Local debugging and observability (development only)
- [Canonical Examples](references/examples.md) - Provider × feature working code from vercel/ai/examples

## Related Skills

- `ai-sdk-7` - AI SDK 7 development, HarnessAgent, WorkflowAgent, telemetry, realtime, video, and v6-to-v7 migration
- `ai-sdk-6` - AI SDK 6 development with ToolLoopAgent, Output patterns, MCP, middleware, tools, and UI hooks
