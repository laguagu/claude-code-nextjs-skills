---
name: ai-app
description: >-
  Builds full-stack Next.js AI applications with the AI SDK and the shadcn/ui
  AI Elements patterns.
  Use when creating a chatbot, agent dashboard or custom AI application.
---

# AI application setup

Build the requested app around its users, data and operations. Keep the existing
stack and SDK major unless migration is part of the task; use Bun for new
JavaScript projects.

1. Resolve the installed AI SDK major through `ai-sdk`; use `ai-sdk-6` or
   `ai-sdk-7` for implementation. For a new app, default to **AI SDK 7**: `ai@7`,
   `@ai-sdk/react@4` and each provider package at `latest` (provider majors
   differ; Node.js 22+). Keep v6 only when a required dependency pins it. Build
   new chat UI from the AI Elements patterns in shadcn/ui
   (https://ui.shadcn.com/docs/ai-elements); they need no v7 patch. The older
   elements.ai-sdk.dev library (`ai-elements`) will be deprecated at the end of
   November 2026, targets v6, and its `context.tsx` fails a v7 typecheck until
   patched. Read version-matched `ai/docs/` and provider docs before using web
   examples.
2. Use `nextjs-shadcn` for framework setup and `frontend-design` for visual
   direction. Compose chat UI from the shadcn/ui patterns (Message, Bubble,
   Message Scroller, Trace; the `shadcn` skill). For a chatbot,
   shadcn-ui/chatbot-template is a starting point after upgrading its Next.js
   (16.3.6) to 16.4.1+. Use `ai-elements` only for components already copied
   from elements.ai-sdk.dev. Inspect installed source instead of assuming
   registry props.
3. Keep provider credentials and authorization on the server. Resolve model IDs
   from configuration or the selected provider's catalog.
4. Implement the smallest complete user flow. Add persistence, approvals,
   attachments, search, suggestions or dashboards when the app needs them.
5. Match the server stream to the client transport. Verify a second turn,
   relevant tool states, safe failures and mobile behavior, alongside the
   project's typecheck/build.

## Read for the app being built

- [Chatbot](references/chatbot.md): conversation and stream contracts.
- [Agent dashboard](references/agent-dashboard.md): execution, approval and run state.
- [Examples](references/examples.md): current official implementations.
- [Project structure](references/project-structure.md): boundaries without a fixed tree.
- `nextjs-chatbot`: durable history, feedback, embedding and production checks.

These references describe requirements, not copyable production templates.
