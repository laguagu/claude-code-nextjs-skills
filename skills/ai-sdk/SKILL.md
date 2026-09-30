---
name: ai-sdk
description: 'Answer questions about the AI SDK and help build AI-powered features. Use when developers ask about Vercel AI SDK, generateText, streamText, ToolLoopAgent, useChat, providers, tools, structured output, embeddings, streaming, or adding AI to an app. First identify the installed major version and route version-specific work: use ai-sdk-7 for AI SDK 7 features/migrations such as WorkflowAgent, HarnessAgent, reasoning, runtime/tools context, toolApproval, telemetry, realtime, or v6-to-v7 upgrades; use ai-sdk-6 for v6 code.'
---

# AI SDK version and documentation routing

Identify `ai` and the provider/React package versions in the relevant workspace's
manifest, lockfile or installed package. Keep the installed major unless an
upgrade is requested.

- AI SDK 7 implementation or migration: use `ai-sdk-7`.
- AI SDK 6 maintenance: use `ai-sdk-6`.
- Unknown, mixed or older versions: resolve them before applying either API set.
- New apps: verify the current release and package compatibility in the
  [official docs](https://ai-sdk.dev/docs).

## Find the API that matches the app

Search the resolved package's `docs/` and `src/` first, including provider
packages. Monorepo hoisting and Yarn PnP may change the paths; do not install
or upgrade a dependency solely to obtain docs.

When local documentation is unavailable, use the matching docs version or
repository tag. The [documentation search](https://ai-sdk.dev/api/search-docs?q=useChat)
and Markdown page variants help locate the relevant feature. Repository main
and the default website can target a newer major than the app.

Choose model IDs from the app's provider configuration or current provider
catalog. The [Gateway catalog](https://ai-gateway.vercel.sh/v1/models) can aid
discovery; its IDs and capability availability do not imply that another
provider accepts them. Choose capability, latency and cost for the task.

## Targeted references

- [Common errors](references/common-errors.md): obsolete names and protocol mismatches.
- [Typed agents](references/type-safe-agents.md): UI inference and server/client boundaries.
- [DevTools](references/devtools.md): local debugging.
- [Examples](references/examples.md): provider-specific official code.

Use defaults when they fit. Typecheck changed integrations and exercise their
streaming/tool path; a supported symbol can still be used with the wrong
callback scope, result semantics or provider.
