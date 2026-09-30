---
name: ai-app
description: >-
  Builds full-stack Next.js AI applications with the AI SDK and ai-elements.
  Use when creating a chatbot, agent dashboard or custom AI application.
---

# AI application setup

In an existing app, keep its package manager, SDK major, shadcn base and
aliases unless migration is part of the task. A new app uses these defaults:

| Choice | Default |
| --- | --- |
| Tooling | Bun; AI SDK 7 packages need Node.js 22+ |
| Scaffold | `bunx --bun shadcn@latest init --name <app> --template next`; base and preset via `nextjs-shadcn` |
| AI SDK | **v7**: `ai@7`, `@ai-sdk/react@4`, provider packages `@4` (e.g. `@ai-sdk/anthropic@4`), `zod`. Use v6 only when a required dependency pins it |
| Chat UI | AI Elements, only the components used: `bunx --bun ai-elements@latest add conversation message prompt-input` |
| Model ID | From env/config or the provider's current catalog, not from memory |

## Sources

Read version-matched local sources first: `node_modules/ai/docs/` (Next.js
quickstart `02-getting-started/02-nextjs-app-router.mdx`, chat UI
`04-ai-sdk-ui/`), the packages' `.d.ts`, and the generated
`components/ai-elements/*.tsx`. The [AI SDK docs](https://ai-sdk.dev/docs) are
the fallback and describe the newest major. Use `ai-sdk-7` (or `ai-sdk-6`) for
API boundaries, `ai-elements` for components, `nextjs-shadcn` and
`frontend-design` for the interface.

## Integration facts

- `useChat()` defaults to `DefaultChatTransport`, posting to `/api/chat` and
  expecting a UI-message stream. In v7 return
  `createAgentUIStreamResponse({ agent, uiMessages })` or
  `createUIMessageStreamResponse({ stream: toUIMessageStream({ stream: result.stream }) })`;
  `result.toUIMessageStreamResponse()` is the v6 form, deprecated in v7. A text
  stream needs `TextStreamChatTransport` and carries no tool, reasoning or source parts.
- `createAgentUIStreamResponse` validates `uiMessages` against the agent's tools
  and converts them; with `streamText`, call `validateUIMessages` and
  `await convertToModelMessages` yourself.
- UI streams default to `sendReasoning: true` and `sendSources: false`;
  citations never reach the client without `sendSources: true`.
- Type the client from the agent: export
  `type AgentUIMessage = InferAgentUIMessage<typeof agent>` and use
  `useChat<AgentUIMessage>()` through `import type`, keeping server code out of
  the bundle.
- Keep credentials, model choice and tool authorization on the server. A chat
  rendered under `template.tsx` remounts on navigation; keep conversation state
  in a layout or page.

## Done when

The project's typecheck/build passes and, in a browser, a streamed reply, a
second turn, the relevant tool states (including approve/deny), a safe error
and the mobile layout work. Report what was checked.

## Read for the app being built

- [Chatbot](references/chatbot.md): parts, attachments, search and model choice.
- [Agent dashboard](references/agent-dashboard.md): run state, tool UI and approvals.
- `nextjs-chatbot`: persistence, approval security, feedback, embedding and evals.
