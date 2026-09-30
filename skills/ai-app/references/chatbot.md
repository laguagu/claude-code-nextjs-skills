# Chatbot contract

Use the installed-major quickstart in [AI SDK docs](https://ai-sdk.dev/docs/getting-started/nextjs-app-router)
and inspect the installed AI Elements components.

A complete conversation needs matching stream/transport protocols, controlled
input, text and relevant non-text parts, cancellation, recoverable errors and
a second turn. Persist UI messages if history must restore the same tool
results, sources and attachments; reconstruct model input with the SDK's
validated conversion rather than casting browser JSON.

Add web search only when the task needs current or external evidence. Verify
the selected provider's tool and citation capabilities in its current docs.
Display actual source URLs; a tool result is not automatically a citation.

Attachments need server-side limits and provider-compatible media handling.
A model selector needs an allowed server-side model set and compatibility with
the conversation's features. Neither belongs in every chat.

For server persistence, authorization, approval and browser verification, use
`nextjs-chatbot`. For component composition, use `ai-elements`.
