---
title: AI SDK 7 UI Hooks
description: useChat, UIMessage streams, tool parts, approvals, harness UI, and workflow UI.
---

# Chat, workflow and harness UI

`useChat` manages conversation/stream state, while the component owns input.
Configure `DefaultChatTransport` for ordinary HTTP chat and return matching
UI-message chunks. Infer tool types; narrow part state before reading
input/output, and handle dynamic parts separately.

Manual approval requests are parts in `approval-requested` state; answer with
`addToolApprovalResponse({ id: part.approval.id, approved })`. Automatic policy
decisions do not need a fabricated user response. Continue with
`sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithApprovalResponses`
(or `...WithToolCalls` for client-executed tools). The client `useChat`
`onFinish` keeps its name in v7.

Persist validated UI messages for UI restoration. Preserve protocol-valid
tool-call/result and provider context when building model history; do not
strip all non-text parts as a universal fix.

Harness routes authorize/create/resume a session, inject it into the call and
persist opaque resume state. The harness owns history.

Workflow routes convert model chunks at the response boundary. For
`WorkflowChatTransport`, the POST response carries an `x-workflow-run-id`
header and `GET {api}/{runId}/stream?startIndex=<n>` returns the run's readable
stream for reconnection. Ordinary chat resumption is a different contract.

Read [AI SDK UI docs](https://ai-sdk.dev/docs/ai-sdk-ui/overview) and the selected
agent package's integration guide. Test cancellation, direct reload and a
second restored turn alongside successful streaming.
