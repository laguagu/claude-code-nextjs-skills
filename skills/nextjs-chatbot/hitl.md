# HITL Tool Approval

Human-in-the-loop (HITL) approval gates a tool's execution behind an explicit user approve/deny step. The AI SDK v6 handles state tracking; you wire up the UI.

## Tool definition

```ts
// lib/ai/tools/suggest-expert-handoff.ts
import { tool } from "ai";

export const myApprovalTool = tool({
  description: "...",
  inputSchema: z.object({ ... }),
  outputSchema: z.object({ ... }),
  needsApproval: true,   // <-- enables HITL
  execute: async (input) => {
    // Runs only AFTER user approves
    return { ... };
  },
});
```

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

Pass `addToolApprovalResponse` down to the message component.

## 5-state render machine

The tool part cycles through these states. Handle all of them in the UI.

```
input-streaming / input-available  →  loading shimmer
approval-requested                 →  approve / deny buttons
approval-responded                 →  brief loading shimmer ("Preparing...")
output-available                   →  render the form / result
output-denied                      →  "Cancelled" message
output-error                       →  error message
```

```tsx
// components/chat-message.tsx — inside renderToolPart()
if (part.type === "tool-myApprovalTool") {
  const toolPart = part as typeof part & {
    state: string;
    input?: { topic?: string };
    output?: MyOutput;
    errorText?: string;
    approval?: { id: string };
  };

  // Loading
  if (toolPart.state === "input-streaming" || toolPart.state === "input-available") {
    return <Shimmer>Finding options...</Shimmer>;
  }

  // Approve / deny prompt
  if (toolPart.state === "approval-requested" && toolPart.approval) {
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

  // Waiting for tool to execute
  if (toolPart.state === "approval-responded") {
    return <Shimmer>Preparing form...</Shimmer>;
  }

  // Tool executed successfully
  if (toolPart.state === "output-available" && toolPart.output) {
    return <MyResultComponent output={toolPart.output} />;
  }

  // User denied
  if (toolPart.state === "output-denied") {
    return <div className="text-muted-foreground text-sm">Request cancelled.</div>;
  }

  // Tool error
  if (toolPart.state === "output-error") {
    return <div className="text-destructive text-sm">Error: {toolPart.errorText}</div>;
  }

  return null;
}
```

## System prompt guidance

Tell the agent how to handle denial and what NOT to include in text responses:

```
suggestExpertHandoff - asks user for approval, then shows a contact form.
If the user denies the approval, do not retry. Acknowledge the cancellation.
IMPORTANT: Do NOT list expert names in your text — the form already shows them.
Tell the user to fill in the form below. Keep it to 1-2 sentences.
```

