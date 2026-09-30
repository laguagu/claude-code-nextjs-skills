# Conversation persistence

Use stable conversation and message IDs shared by the UI, storage and feedback
API. Authenticate ownership on every history, message, feedback, delete and
resume operation; possession of an ID is not authorization.

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
provider-stored state. If restored replay fails, inspect the retained sequence
and the provider's supported replay mode. A deliberately stateless text-only
history may require removing provider IDs and dependent parts together; that
is a provider-specific conversion decision, not a universal repair. Test the
second question after a reload against the actual provider.

## Completion and feedback

Use the completion callback of the correct stream layer. Core v7 callback
renames do not rename the client `useChat.onFinish`; inspect the callback
payload rather than assuming every API returns the full conversation.

Feedback can arrive before the assistant row is committed. Represent that
pending state explicitly and use bounded retries or a server queue. Associate
each retry with the current vote/generation so an older request cannot overwrite
a later choice. Preserve optimistic state only after a confirmed write; handle
non-success responses.

## Disconnect, resume and deletion

Choose whether cancellation should stop model work. Background stream
consumption can enable saving after a disconnect within the hosting lifetime;
it does not survive a process crash by itself.

[Resumable streams](https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-resume-streams)
need stream storage, conversation-to-stream mapping and authorized endpoints.
Check the installed transport's abort/resume compatibility; `resume: true`
alone does not implement storage or durable execution.

Database cascades delete related database rows. Define cleanup for uploaded
files, external stores, traces and backups separately.
