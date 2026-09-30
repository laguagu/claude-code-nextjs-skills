---
name: ai-app
description: >-
  Builds full-stack Next.js AI applications with the AI SDK and ai-elements.
  Use when creating a chatbot, agent dashboard or custom AI application.
---

# AI application setup

Build the requested app around its users, data and operations. Keep the existing
stack and SDK major unless migration is part of the task; use Bun for new
JavaScript projects.

1. Resolve the installed AI SDK major through `ai-sdk`; use `ai-sdk-6` or
   `ai-sdk-7` for implementation. For a new app, verify the current supported
   release and compatible provider/React packages before installing.
2. Use `nextjs-shadcn` for framework setup and `frontend-design` for visual
   direction. Use `ai-elements` when its components fit the required chat UI;
   inspect installed source instead of assuming registry props.
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
