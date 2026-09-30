---
name: ai-sdk-6
description: Vercel AI SDK v6 development, for projects already on ai@6. Use when building or maintaining AI agents, chatbots, tool integrations, streaming apps, or structured output in a v6 codebase. New projects and ai@7 code use ai-sdk-7; an unknown version goes through ai-sdk. Covers ToolLoopAgent, useChat, generateText, streamText, tool approval, smoothStream, provider tools, MCP integration, and Output patterns.
---

# AI SDK 6 maintenance

Apply this skill only to `ai@6` projects. Use `ai-sdk` when the major is
unknown and `ai-sdk-7` for an authorized upgrade. Add AI SDK packages with the
`ai-v6` dist-tag (`@ai-sdk/openai@ai-v6`, `@ai-sdk/react@ai-v6`); `latest` is
the v7 line.

Read `node_modules/ai/docs/` and `src/` for the installed minor (in a monorepo,
from the app using the dependency); `docs/` paths named here mirror
`content/docs/` at the `ai@<version>` tag. Fallbacks when `docs/` is absent
(`ai` < 6.0.32): that tag, the [v6 web docs](https://ai-sdk.dev/v6/docs), or
the checked [v6 snapshot](https://github.com/vercel/ai/tree/ai%406.0.297/content/docs)
linked below. Unversioned web docs and repository main describe v7.

## Boundaries that differ from old and new code

- Text functions use `system`; `ToolLoopAgent` uses `instructions`.
- Loop limits use `stopWhen: stepCountIs(...)`. `generateText`/`streamText`
  default to one step (tools run, no follow-up text); `ToolLoopAgent` to 20.
- `convertToModelMessages` is async; await it.
- Use text functions with `Output` for new schema output; legacy object
  functions are deprecated.
- Tools use `inputSchema`; SDK-executed approval is tool-level `needsApproval`.
  V7 agent-level `toolApproval` is not a v6 substitute.
- `useChat` (`@ai-sdk/react`) owns messages and status, not form input:
  `sendMessage({ text })`, `transport: new DefaultChatTransport({ api })`. The
  route returns `result.toUIMessageStreamResponse()` or
  `createAgentUIStreamResponse({ agent, uiMessages })`.
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
