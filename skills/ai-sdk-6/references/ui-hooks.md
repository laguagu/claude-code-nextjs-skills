# AI SDK 6 chat UI and persistence

`useChat` manages messages, stream status and conversation operations. Keep form
input in the UI, and configure HTTP/body behavior through the transport. Confirm
the installed callback signatures rather than treating core `onFinish` and
client `onFinish` as one API.

Use inferred UI-message/tool types and narrow part state before reading
input/output. Validate restored UI messages on the server and use the SDK's
model-message conversion. Store UI messages when the UI must restore tool
results, sources, attachments and metadata.

Stable message IDs connect client rendering, storage and feedback. When sending
only the new message, load and authorize the canonical history on the server.
Client-provided history and chat IDs are untrusted.

Decide what client disconnect and cancellation mean. If server completion/save
must continue after disconnect, follow the documented stream consumption
pattern and the hosting runtime's lifetime limits. This does not provide
durability or resumption automatically.

Resumption and abort behavior can conflict; verify the chosen recovery contract.
Stop the active stream before resetting or switching a conversation.

Read [chatbot persistence](https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-message-persistence)
and [resumable streams](https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-resume-streams)
with v6 selected.
