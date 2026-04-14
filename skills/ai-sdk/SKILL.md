---
name: ai-sdk
description: 'Answer questions about the AI SDK and help build AI-powered features. Use when developers: (1) Ask about AI SDK functions like generateText, streamText, ToolLoopAgent, embed, or tools, (2) Want to build AI agents, chatbots, RAG systems, or text generation features, (3) Have questions about AI providers (OpenAI, Anthropic, Google, etc.), streaming, tool calling, structured output, or embeddings, (4) Use React hooks like useChat or useCompletion. Triggers on: "AI SDK", "Vercel AI SDK", "generateText", "streamText", "add AI to my app", "build an agent", "tool calling", "structured output", "useChat".'
argument-hint: "[question or feature]"
---

## Prerequisites

Before searching docs, check if `node_modules/ai/docs/` exists. If not, install **only** the `ai` package using the project's package manager (e.g., `bun add ai`).

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
2. Search `node_modules/ai/docs/` and `node_modules/ai/src/` for current APIs
3. If not found locally, search ai-sdk.dev documentation (instructions below)
4. Never rely on memory - always verify against source code or docs
5. **`useChat` has changed significantly** - check [Common Errors](references/common-errors.md) before writing client code
6. **Always fetch current model IDs** - Never use model IDs from memory. A public catalog of current IDs across providers is available at `https://ai-gateway.vercel.sh/v1/models` — useful purely for discovery, not a recommendation to use Gateway as a runtime provider. Example: `curl -s https://ai-gateway.vercel.sh/v1/models | jq -r '[.data[] | select(.id | startswith("anthropic/")) | .id] | reverse | .[]'` (swap `anthropic/` for `openai/`, `google/`, etc.). Use the model with the highest version number (e.g., `claude-sonnet-4-6` over `claude-sonnet-4-5` over `claude-3-5-sonnet`).
7. Run typecheck after changes to ensure code is correct
8. **Be minimal** - Only specify options that differ from defaults. When unsure of defaults, check docs or source rather than guessing or over-specifying.

If you cannot find documentation to support your answer, state that explicitly.

## Finding Documentation

### ai@6.0.34+

Search bundled docs and source in `node_modules/ai/`:

- **Docs**: `grep "query" node_modules/ai/docs/`
- **Source**: `grep "query" node_modules/ai/src/`

Provider packages include docs at `node_modules/@ai-sdk/<provider>/docs/`.

### Earlier versions

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

Always use the `ToolLoopAgent` pattern. Search `node_modules/ai/docs/` for current agent creation APIs.

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
