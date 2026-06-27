---
title: Tools in AI SDK 7
description: Tool schemas, context, approvals, MCP Apps, and sandbox handles.
---

# Tools in AI SDK 7

Define tools with `inputSchema` and keep tool implementations narrow. Use
context for server-side state instead of adding secrets or app metadata to the
prompt.

## Tool Definition

```ts
import { tool } from 'ai';
import { z } from 'zod';

export const customerLookup = tool({
  description: 'Look up customer account details.',
  inputSchema: z.object({
    customerId: z.string(),
  }),
  contextSchema: z.object({
    apiKey: z.string(),
    region: z.string(),
  }),
  execute: async ({ customerId }, { context }) => {
    return lookupCustomer({
      customerId,
      apiKey: context.apiKey,
      region: context.region,
    });
  },
});
```

`parameters` is legacy; use `inputSchema`.

## Runtime Context vs Tool Context

Use `runtimeContext` for shared agent/generation state:

- request IDs
- tenant IDs
- user role or plan
- feature flags
- progress state

Use `toolsContext` for per-tool values:

- API keys
- scoped tokens
- default options
- permissions needed by one tool

Each tool receives only its own context entry after `contextSchema` validation.
Tool descriptions can also be functions that adapt based on the validated tool
context.

## Updating Context Between Steps

If context needs to change after a tool result, inspect previous steps in
`prepareStep` and return updated `runtimeContext` or `toolsContext`. Treat tool
context as immutable inside `execute`.

For `WorkflowAgent`, keep context serializable because it may be persisted and
replayed by the workflow runtime.

## Tool Approval

Use `toolApproval` for sensitive AI SDK-executed tools:

```ts
const result = await generateText({
  model: __MODEL__,
  tools: { processPayment },
  toolApproval: {
    processPayment: async ({ amount }, { runtimeContext }) => {
      if (runtimeContext.role !== 'admin') {
        return { type: 'denied', reason: 'Only admins can send payments' };
      }
      return amount > 1000 ? 'user-approval' : undefined;
    },
  },
  runtimeContext: { role: 'admin' },
  messages,
});
```

Status values are `not-applicable`, `approved`, `denied`, and `user-approval`.
`undefined` is treated as `not-applicable`.

Manual approvals require a second call with a `tool-approval-response` message.
In `useChat`, approval requests appear as tool parts with
`state: 'approval-requested'`; respond with `addToolApprovalResponse`.

For sensitive client-controlled approval flows, use
`experimental_toolApprovalSecret` with `generateText` or `streamText` so the
server signs and verifies approvals. Check current docs before applying this to
agent classes.

## WorkflowAgent Approval

`WorkflowAgent` uses tool-level `needsApproval` because the workflow runtime can
suspend and resume around approvals:

```ts
bookFlight: tool({
  description: 'Book a flight.',
  inputSchema: z.object({ flightId: z.string() }),
  needsApproval: true,
  execute: bookFlightStep,
});
```

`needsApproval` can also be a function of parsed input.

## Sandbox Handles

Tools that need an execution environment can receive `experimental_sandbox` in
their execution options. Treat it as a live runtime handle, not durable context.
Do not store sandbox sessions in `runtimeContext` or `toolsContext`.

Harness host-executed tools receive a restricted sandbox session so they can
operate in the harness workspace without owning the native sandbox lifecycle.

## MCP Apps

AI SDK 7 supports MCP Apps for richer tool and UI integrations. Use MCP Apps
when an MCP server needs to expose model-visible tools plus app-only metadata or
UI rendered in a sandboxed iframe.

In React, MCP App UI uses `experimental_MCPAppRenderer` from `@ai-sdk/react`.
Keep app-only tools separate from model-visible tools and validate resource
loading on the server.

## Gotchas

- `toolApproval` does not apply to provider-executed tools.
- `HarnessAgent` built-in tools use adapter permissions, not host
  `toolApproval`.
- Subagent tools cannot use `toolApproval`.
- Tool timeout failures become tool errors so the model can respond or retry.
- Check `part.dynamic` before assuming a tool UI part is one of your typed tools.
