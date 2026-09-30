# Chatbot contract

A complete conversation needs matching stream/transport protocols, controlled
input, a working `stop()`, recoverable errors and a second turn. Render the
part types the server sends: text, reasoning, `source-url`/`source-document`,
`file`, and typed `tool-<name>` plus `dynamic-tool` parts.

Persist UI messages if history must restore the same tool results, sources and
attachments. Use `nextjs-chatbot` for IDs, replay, approval security and
browser verification.

AI Elements `PromptInput` converts `blob:` URLs to data URLs before `onSubmit`,
so attachments travel inline in the chat request. Its `accept`, `maxFiles` and
`maxFileSize` limits are client-side only: enforce type and size on the server,
and upload large files instead of inlining them.

Add web search only when the task needs current or external evidence. Check the
selected provider's search tool and citation support in its package docs.
Display actual source URLs (`sendSources: true`); a tool result is not
automatically a citation.

A model selector needs a server-side allowlist and compatibility with the
conversation's tools, attachments and reasoning. Neither a selector nor
attachments belongs in every chat.
