---
name: nextjs-chatbot
description: "Production Next.js web-chat integration: tool approval, persisted conversations, tool result UI, grounded retrieval, follow-up suggestions and embedded widgets. Use when building or debugging a web chatbot that needs these features. Use ai-app for scaffolding and ai-sdk for general SDK APIs; multi-platform bots use Chat SDK."
---

# Production Next.js chatbots

Use this skill for web-chat integration: persisted conversations, tool approval,
tool result UI and an embedded widget. Use `ai-app` for scaffolding and its
new-app defaults, `ai-sdk` to resolve the SDK version, and `ai-elements` for
component contracts. For multi-platform messaging, consult [Chat SDK](https://chat-sdk.dev/).

Keep the project's stack. A chatbot does not inherently need PostgreSQL,
Zustand, MCP servers or every message action.

Read the installed `node_modules/ai/docs/04-ai-sdk-ui/` first (message
persistence, tool usage, error handling, resume streams); the linked
ai-sdk.dev pages are the fallback and describe the newest major.

## Integration contracts

- Match `ai`, `@ai-sdk/react` and provider versions before writing API calls.
  Use `ai-sdk-7` for v7 and `ai-sdk-6` for existing v6 projects; core callback
  renames do not imply renaming the separate `useChat.onFinish`.
- Authenticate conversation access, validate request data and authorize tools
  on the server. Client history, context, model IDs and consent flags are
  untrusted; prompts cannot enforce tenant isolation or permissions.
- Store validated UI messages with stable IDs when the full conversation UI
  must be restored. Convert model history through the installed SDK's helpers;
  keep required tool-call/result and provider reasoning relationships intact.
- Determine what happens on cancellation, disconnect, reload and retries.
  Consuming a stream after disconnect still depends on the hosting lifetime;
  durable execution needs a supported durable runtime.
- The UI stream's `onError` return string goes to the browser verbatim (default
  `'An error occurred.'`); never return `String(error)`. A non-2xx route
  response reaches `useChat`'s `error.message` as the raw response body. Log
  redacted details with a correlation ID and send fixed public text. An error
  after the stream opened still arrives with HTTP 200.
- SDK UI-stream responses already send `x-accel-buffering: no`; set it on
  streams you build yourself. It helps nginx-style proxies only, so verify
  the deployed path actually streams.

## Chat surface

Keep the answer, relevant tool results and useful sources readable. Add
feedback, regenerate, delete or suggestions when the product needs them;
avoid a repeated “Answer” heading or an action toolbar on every message by
default. Use the `icons` skill for icon choice and `nextjs-shadcn` for the surrounding interface.

Follow streamed output while the reader is at the bottom; preserve their place
when they scroll away or load earlier history. AI Elements `Conversation`
(`use-stick-to-bottom`) and `MessageResponse` (Streamdown) already handle
following and streaming Markdown; shadcn's
[Message Scroller](https://ui.shadcn.com/docs/react/message-scroller)
(`@shadcn/react`) adds turn anchoring and prepend preservation. Verify nested
lists, long links and code blocks.

Derive turn completion from `useChat` status (`submitted`/`streaming`) rather
than a momentary gap between tools. Call `stop()` before switching or clearing
conversations. Browser storage must not make the first client render disagree
with server-rendered consent or history.

## Read for the feature

- [Tool approval](hitl.md): policy, replay security and UI transitions.
- [Persistence](persistence.md): IDs, history replay, feedback and resumption.
- [Tool rendering](tool-rendering.md): typed states and safe output.
- [Popup/embedding](popup-widget.md): focus, scrolling and host boundaries.
- [Retrieval](search.md): structured filters and evaluated search choices.
- [Suggestions](suggestions.md): optional, grounded next actions.
- [Web search](web-search.md): source scope, freshness and provider capability.
- [Verification](testing.md): UI transitions and model/retrieval evals.

Exercise a second turn after restoring history, approval and denial, tool
failure, cancellation, fast conversation switching and the deployed stream
path. Report the behaviors actually checked.
