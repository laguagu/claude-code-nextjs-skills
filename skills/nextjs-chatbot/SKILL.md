---
name: nextjs-chatbot
description: "Production Next.js web-chat integration: tool approval, persisted conversations, tool result UI, grounded retrieval, follow-up suggestions and embedded widgets. Use when building or debugging a web chatbot that needs these features. Use ai-app for scaffolding and ai-sdk for general SDK APIs; multi-platform bots use Chat SDK."
---

# Production Next.js chatbots

Use this skill for web-chat integration: persisted conversations, tool approval,
tool result UI and an embedded widget. Use `ai-app` for scaffolding,
`ai-sdk` to resolve the SDK version, and `ai-elements` for component contracts.
For multi-platform messaging, consult [Chat SDK](https://chat-sdk.dev/).

Keep the project's stack. Choose the model, reasoning setting, storage and
client state from the product's quality, latency and privacy requirements.
A chatbot does not inherently need PostgreSQL, Zustand, MCP servers or every
message action.

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
- Log redacted diagnostics with a correlation ID. Return a safe public error
  for failed HTTP requests and in-stream failures; an error after headers have
  been sent cannot change the HTTP status.
- Verify actual proxy streaming and buffering configuration. A
  `X-Accel-Buffering: no` header helps supported nginx setups; it is not a
  guarantee that every host streams without buffering.

## Chat surface

Keep the answer, relevant tool results and useful sources readable. Add
feedback, regenerate, delete or suggestions when the product needs them;
avoid a repeated “Answer” heading or an action toolbar on every message by
default. Use the `icons` skill for icon choice and `nextjs-shadcn` for the surrounding interface.

Follow streamed output while the reader is at the bottom; preserve their place
when they scroll away or load earlier history. Use an existing compatible
scroll primitive when it fits; shadcn's
[Message Scroller](https://ui.shadcn.com/docs/react/message-scroller) is one option.
Render Markdown through the application's
renderer and verify nested lists, long links and code blocks.

Derive turn completion from chat-level status rather than a momentary gap
between tools. Stop or isolate the current generation before switching
conversations. Browser storage must not make the first client render disagree
with server-rendered consent or history.

## Read for the feature

- [Build checklist](checklist.md): product decisions and integration checks.
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
