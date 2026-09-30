# Conversation persistence

Use stable conversation and message IDs shared by the UI, storage and feedback
API. Authenticate ownership on every history, message, feedback, delete and
resume operation; possession of an ID is not authorization.

`useChat` creates user message IDs; keep them. A new assistant message gets a
server ID only when the UI stream receives `generateMessageId` (e.g.
`createIdGenerator({ prefix: 'msg', size: 16 })`). Without it the client
invents one that storage and feedback cannot match.

Store validated `UIMessage` data when restoring the same tool/source interface
matters. Keep schema/version information for migrations and retention rules.
If messages reference a session row, await its creation before dependent
writes. Make completion saves idempotent with an appropriate unique key; do
not replace missing IDs with history-array positions.

## Model replay

Prefer server-owned history plus a validated new client message. Validate
stored tools, metadata and custom data parts with compatible schemas before
processing. Use the installed `convertToModelMessages` contract, including its
async behavior. See [message persistence](https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-message-persistence).

UI storage and model context are different concerns. Select complete turns
within the context budget, preserving required tool-call/result and reasoning/
provider relationships. Do not blanket-delete every `tool-*`, step or
`providerMetadata` part.

An OpenAI Responses item ID can depend on associated reasoning items or
provider-stored state. The symptom is a second turn after reload failing with
`... was provided without its required 'reasoning' item` or `Item 'rs_...' of
type 'reasoning' was provided without its required following item`: stored
parts keep `providerMetadata.openai.itemId`, which the provider replays as
item references (with `store` on), but a paired item is missing, e.g. after
`sendReasoning: false` or trimming reasoning parts. Inspect the retained
sequence and the provider's supported replay mode. A deliberately stateless
text-only history may require removing provider IDs and dependent parts
together; that is a provider-specific conversion decision, not a universal
repair. Test the second question after a reload against the actual provider.

## Completion and feedback

Save from the UI stream's completion callback (`onEnd` in v7, `onFinish` in
v6); it receives the updated `messages` and `isAborted`. Core v7 callback
renames do not rename the client `useChat.onFinish`; inspect the callback
payload rather than assuming every API returns the full conversation.

Feedback can arrive before the assistant row is committed. Represent that
pending state explicitly and use bounded retries or a server queue. Associate
each retry with the current vote/generation so an older request cannot overwrite
a later choice. Preserve optimistic state only after a confirmed write; handle
non-success responses.

## Disconnect, resume and deletion

Choose whether cancellation should stop model work. Calling
`result.consumeStream()` (not awaited) before returning the response lets the
save run after a disconnect within the hosting lifetime; it does not survive a
process crash by itself.

[Resumable streams](https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-resume-streams)
need stream storage, conversation-to-stream mapping and authorized endpoints;
`resume: true` alone does not implement storage or durable execution. In a
resumable setup `stop()` is only a client disconnect: generation continues
unless your own stop endpoint cancels the server work.

Database cascades delete related database rows. Define cleanup for uploaded
files, external stores, traces and backups separately.
