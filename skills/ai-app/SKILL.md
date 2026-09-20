---
name: ai-app
description: |
  Full-stack AI application generator with Next.js, AI SDK, and ai-elements.
  Use when creating chatbots, agent dashboards, or custom AI applications.

  Triggers: chatbot, chat app, agent dashboard, AI application, Next.js AI,
  useChat, streamText, ai-elements, build AI app, create chatbot
---

# AI App Generator

Scaffold an AI web app, then use the version-specific SDK and UI references.

## Workflow

1. Infer the app type, required tools, persistence and visual direction from the
   request. Ask only for decisions that materially affect the result.
2. In an existing app, inspect its lockfile, SDK major, shadcn base and aliases.
   Keep those choices unless migration is requested. Use `ai-sdk` to resolve
   version-specific APIs before installing packages.
3. For a new Next.js app, use Bun and the shadcn CLI:

   ```bash
   bunx --bun shadcn@latest init --name my-ai-app --template next
   ```

4. Select the SDK major before installing compatible provider and React
   packages. The bundled templates target **AI SDK 6**: `ai@6`,
   `@ai-sdk/react@3`, and provider packages compatible with v6 (for example
   `@ai-sdk/anthropic@3`). For v7, use `ai-sdk-7` and its migration guidance;
   do not copy v6 response methods into v7 code.
5. Add only the AI Elements components the app needs. Inspect their installed
   source for props; registry components can evolve independently of the SDK.
6. Configure the selected provider's server-side environment variables and a
   model ID verified from the project's config or provider catalog.
7. Implement the route and UI with matching stream protocols. Validate incoming
   messages, authenticate protected operations, and return safe client errors.
8. Run typecheck/build and verify streaming, a second conversation turn, tool
   execution/approval, failure handling and mobile layout in a browser.

## Read when needed

- [Chatbot template](references/chatbot.md): v6 conversation and message parts.
- [Agent dashboard](references/agent-dashboard.md): v6 tool-loop UI and approvals.
- [Examples](references/examples.md): focused v6 feature examples.
- [Project structure](references/project-structure.md): optional larger-app layout.
- `ai-sdk-6` / `ai-sdk-7`: installed-major APIs and provider integrations.
- `ai-elements`: component installation and composition.
- `nextjs-chatbot`: persistence, feedback, approval states and evals.
- `nextjs-shadcn` / `frontend-design`: framework setup and visual design.

Treat templates as starting points, not production-ready authentication,
authorization or persistence implementations.
