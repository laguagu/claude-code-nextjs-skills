---
name: ai-sdk-6
description: Vercel AI SDK v6 development, for projects already on ai@6. Use when building or maintaining AI agents, chatbots, tool integrations, streaming apps, or structured output in a v6 codebase. New projects and ai@7 code use ai-sdk-7; an unknown version goes through ai-sdk. Covers ToolLoopAgent, useChat, generateText, streamText, tool approval, smoothStream, provider tools, MCP integration, and Output patterns.
---

# AI SDK 6 maintenance

Apply this skill only to `ai@6` projects. Resolve compatible provider and UI
packages from the existing manifest/lockfile. Use `ai-sdk` when the major is
unknown and `ai-sdk-7` for an authorized upgrade.

Read the resolved `ai/docs/`, provider docs and source/types for the exact minor
release. In a monorepo, resolve from the app using the dependency. Default web
docs and repository main can describe v7. If installed docs are unavailable,
select the `ai@<resolved-version>` tag in `vercel/ai` and read `content/docs/`.
Feature links here use a checked [v6 documentation snapshot](https://github.com/vercel/ai/tree/ai%406.0.297/content/docs)
as a fallback; match the project's release when available. This tag selects
documentation, not an application dependency version.

## Boundaries that differ from old and new code

- Text functions use `system`; `ToolLoopAgent` uses `instructions`.
- Loop limits use `stopWhen: stepCountIs(...)`.
- Use text functions with `Output` for new schema output; legacy object
  functions are deprecated.
- Tools use `inputSchema`; SDK-executed approval is tool-level `needsApproval`.
  V7 agent-level `toolApproval` is not a v6 substitute.
- React `useChat` owns messages and stream status, not form input. Use the
  appropriate transport and UI-message response protocol.
- Core completion callbacks are `onFinish`; result `usage` is final-step usage,
  while `totalUsage` covers all steps.

Use a configured model verified for the actual provider. Typecheck and test a
multi-turn stream with relevant tool/approval/error states after integration changes.

## Read for the feature

- [Agents](references/agents.md): loop limits, call options and context.
- [Core functions](references/core-functions.md): output and stream contracts.
- [Tools](references/tools.md): execution, approval and typed states.
- [UI hooks](references/ui-hooks.md): transport, restoration and stream lifetime.
- [Middleware](references/middleware.md): provider interception.
- [MCP](references/mcp.md): transport and cleanup.
- [Workflows](references/workflows.md): when a loop needs explicit orchestration.
- [Examples](references/examples.md): version-matched official implementations.
