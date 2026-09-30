# AI SDK 6 chat UI and persistence

`useChat` manages messages, stream status and conversation operations. Keep form
input in the UI, and configure HTTP/body behavior through the transport. Client
`useChat({ onFinish })` and core `streamText({ onFinish })` are different APIs.

Use inferred UI-message/tool types and narrow part state before reading
input/output. On the server: `validateUIMessages` (pass `tools`/schemas), then
`await convertToModelMessages(...)`. Store UI messages when the UI must restore
tool results, sources, attachments and metadata; save them from
`toUIMessageStreamResponse({ originalMessages, generateMessageId, onFinish })`
so IDs are stable (`createIdGenerator`).

When sending only the new message, load and authorize the canonical history on
the server. Client-provided history and chat IDs are untrusted.

Backpressure aborts the model call when the client disconnects. If completion
must be saved anyway, call `result.consumeStream()` without awaiting before
returning the response; hosting lifetime limits still apply.

Resumable streams (`resumable-stream` + Redis, `resume: true`) turn client
`stop()` into a disconnect, not a cancel; add a server stop path. Stop the
active stream before resetting or switching a conversation.

Read `docs/04-ai-sdk-ui/` (`03-chatbot-message-persistence`,
`03-chatbot-resume-streams`, `21-transport`) or the
[v6 persistence guide](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/04-ai-sdk-ui/03-chatbot-message-persistence.mdx)
and [v6 resumable streams](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/04-ai-sdk-ui/03-chatbot-resume-streams.mdx).
