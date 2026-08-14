# HITL Tool Approval

Human-in-the-loop (HITL) approval gates a tool's execution behind an explicit
user approve/deny step. The AI SDK tracks the state; you wire up the UI.

## Contents

- [Where approval is configured (v7)](#where-approval-is-configured-v7)
- [useChat wiring](#usechat-wiring)
- [6-state render machine](#6-state-render-machine)
- [Do not animate this with AnimatePresence](#do-not-animate-this-with-animatepresence)
- [Sensitive tools: sign the approval](#sensitive-tools-sign-the-approval)
- [System prompt guidance](#system-prompt-guidance)

## Where approval is configured (v7)

**Approval is an agent setting, not a tool setting.** `needsApproval: true` on
`tool()` is the v6 API and does nothing in v7 — the tool just executes. Use
`toolApproval` on the agent:

```ts
const agent = new ToolLoopAgent({
  model,
  tools: { suggestExpertHandoff },
  toolApproval: {
    suggestExpertHandoff: "user-approval",
  },
});
```

Every rule resolves to one of four statuses:

| Status | Effect |
|---|---|
| `'not-applicable'` (default, or `undefined`) | execute normally, no approval metadata |
| `'approved'` | record an automatic approval, then execute |
| `'denied'` | record an automatic denial, return a denied output |
| `'user-approval'` | emit an approval request and wait for a response |

Use the object form to attach a reason the UI can show:
`{ type: 'denied', reason: 'Deleting files is disabled in this workspace' }`.

Three shapes, in increasing order of scope:

```ts
// 1. Per-tool map — a fixed policy per tool.
toolApproval: { runCommand: "user-approval" }

// 2. Per-tool function — decide from the parsed input.
//    Also receives toolCallId, messages, toolContext, runtimeContext.
toolApproval: {
  processPayment: async ({ amount }, { runtimeContext }) => {
    if (runtimeContext.role !== "admin") {
      return { type: "denied", reason: "Only admins can send payments" };
    }
    return amount > 1000 ? "user-approval" : undefined;
  },
}

// 3. Generic function — one policy across the whole tool set.
toolApproval: ({ toolCall }) =>
  toolCall.dynamic || toolCall.toolName === "deleteFile"
    ? "user-approval"
    : undefined,
```

For per-request policy (tenant, plan, permissions), return `toolApproval` from
`prepareCall` instead — it is an agent setting, so it can be recomputed per call.

## useChat wiring

```ts
// hooks/use-chat.ts
import { useChat as useAIChat } from "@ai-sdk/react";
import {
  DefaultChatTransport,
  lastAssistantMessageIsCompleteWithApprovalResponses,
} from "ai";

const { messages, addToolApprovalResponse, sendMessage } = useAIChat({
  id: chatId,
  transport: new DefaultChatTransport({ api: "/api/chat", body: () => ({ ... }) }),
  sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithApprovalResponses,
  //                      ^ re-sends automatically after approval/denial
});
```

Pass `addToolApprovalResponse` down to the message component. Call it **only for
manual approvals** — automatic approvals/denials already arrive in the stream as
`approval-requested` / `approval-responded` with `part.approval.isAutomatic ===
true`, and a denied execution continues to `output-denied` on its own.

## 6-state render machine

```
input-streaming / input-available  →  loading shimmer
approval-requested                 →  approve / deny buttons
approval-responded                 →  brief loading shimmer ("Preparing…")
output-available                   →  render the form / result
output-denied                      →  "Cancelled" message
output-error                       →  error message
```

⚠️ **v7 changed the entry sequence.** v6 put an approval-gated part straight into
`approval-requested`. v7 emits `tool-input-available` **first**, then
`tool-approval-request` — so there is now a real loading→approval transition that
did not exist before. Any UI that animates between tool-part states sees a state
change it never saw in v6. See the next section.

```tsx
// components/chat-message.tsx — inside renderToolPart()
if (part.type === "tool-myApprovalTool") {
  const toolPart = part as typeof part & {
    state: string;
    input?: { topic?: string };
    output?: MyOutput;
    errorText?: string;
    approval?: { id: string; isAutomatic?: boolean; reason?: string };
  };

  if (toolPart.state === "input-streaming" || toolPart.state === "input-available") {
    return <Shimmer>Finding options…</Shimmer>;
  }

  if (toolPart.state === "approval-requested" && toolPart.approval) {
    // Automatic decisions land here too — show status, don't ask.
    if (toolPart.approval.isAutomatic) {
      return <Shimmer>Checking approval…</Shimmer>;
    }
    return (
      <div className="rounded-lg border p-4 space-y-3">
        <p className="text-sm font-medium">
          Open a contact form about <strong>{toolPart.input?.topic}</strong>?
        </p>
        <div className="flex gap-2">
          <button onClick={() => addToolApprovalResponse?.({ id: toolPart.approval!.id, approved: true })}>
            Approve
          </button>
          <button onClick={() => addToolApprovalResponse?.({ id: toolPart.approval!.id, approved: false })}>
            Deny
          </button>
        </div>
      </div>
    );
  }

  if (toolPart.state === "approval-responded") {
    return <Shimmer>Preparing form…</Shimmer>;
  }

  if (toolPart.state === "output-available" && toolPart.output) {
    return <MyResultComponent output={toolPart.output} />;
  }

  if (toolPart.state === "output-denied") {
    return (
      <div className="text-muted-foreground text-sm">
        Request cancelled.
        {toolPart.approval?.reason ? ` ${toolPart.approval.reason}` : ""}
      </div>
    );
  }

  if (toolPart.state === "output-error") {
    return <div className="text-destructive text-sm">Error: {toolPart.errorText}</div>;
  }

  return null;
}
```

## Do not animate this with AnimatePresence

Use a plain **keyed `<motion.div>` with an enter animation only** for the state
swap. `<AnimatePresence mode="wait">` defers mounting the incoming variant until
the outgoing one finishes its exit animation — and in a chat tree that exit can
fail to complete, which wedges the card on its loading variant forever while
React has already re-rendered with `state="approval-requested"`. Switching that
same `AnimatePresence` to sync mode mounts the approval card but leaves the dead
loading node behind as a ghost, because the exit still never finishes.

```tsx
<motion.div
  key={variant.key}                    // key change = ordinary remount
  initial={{ opacity: 0, y: 6, scale: 0.98 }}
  animate={{ opacity: 1, y: 0, scale: 1 }}
  transition={{ type: "spring", stiffness: 320, damping: 30 }}
>
  {variant.node(props)}
</motion.div>
```

Dropping the exit animation removes the dependency on motion's unmount lifecycle
entirely, so the card can never wedge or leave a ghost. The fade-in is preserved.

Two things make this worth its own section:

- **The bug was latent in v6.** The part jumped straight to `approval-requested`,
  so the variant key never changed and no swap ever happened. The v7 sequence
  change (above) is what exposed it — i.e. a working v6 approval UI can break on
  upgrade with no code change of your own.
- **Benchmarks cannot see it.** Agent-level fixtures assert which tools were
  called and what the text says. An approval gate produces no text and the tool
  never executes, so the fixture passes while the UI is frozen. Any approval or
  streaming UI change has to be exercised in a browser, or scripted through the
  real `useChat` lifecycle with `createChat` (see [testing.md](testing.md)).

## Sensitive tools: sign the approval

In the `useChat` pattern the client sends the whole message history back each
turn, so a modified client can fabricate an approval response. For tools that do
something irreversible, set `experimental_toolApprovalSecret` on the server-side
`streamText` / agent call — the server then cryptographically verifies that it
issued the approval it is being asked to honour, instead of trusting the
round-tripped message.

## System prompt guidance

Tell the agent how to handle denial and what NOT to include in text responses:

```
suggestExpertHandoff - asks user for approval, then shows a contact form.
If the user denies the approval, do not retry. Acknowledge the cancellation.
IMPORTANT: Do NOT list expert names in your text — the form already shows them.
Tell the user to fill in the form below. Keep it to 1-2 sentences.
```
