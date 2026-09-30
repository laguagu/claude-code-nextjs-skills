---
title: AI SDK 7 UI Hooks
description: useChat, UIMessage streams, tool parts, approvals, harness UI, and workflow UI.
---

# Chat, workflow and harness UI

`useChat` manages conversation/stream state, while the component owns input.
Configure `DefaultChatTransport` for ordinary HTTP chat and return matching
UI-message chunks. Infer tool types; narrow part state before reading
input/output, and handle dynamic parts separately.

Manual approval requests use `addToolApprovalResponse` with the server-issued
approval ID; client tools return results with `addToolOutput`. Automatic policy
decisions do not need a fabricated user response. Continue with
`sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithToolCalls` or
`lastAssistantMessageIsCompleteWithApprovalResponses`.

Persist validated UI messages for UI restoration. Preserve protocol-valid
tool-call/result and provider context when building model history; do not
strip all non-text parts as a universal fix.

Harness routes authorize/create/resume a session, inject it into the call and
persist opaque resume state. The harness owns history.

Workflow routes convert model chunks at the response boundary and expose the
documented run ID / readable stream endpoints for `WorkflowChatTransport`
(`@ai-sdk/workflow/client`). Ordinary chat resumption is a different contract.

Read `docs/04-ai-sdk-ui/` (`03-chatbot-tool-usage`,
`03-chatbot-message-persistence`, `21-transport`), `docs/03-ai-sdk-harnesses/07-ui.mdx`
or the [AI SDK UI docs](https://ai-sdk.dev/docs/ai-sdk-ui/overview). Test
cancellation, direct reload and a second restored turn alongside successful
streaming.
