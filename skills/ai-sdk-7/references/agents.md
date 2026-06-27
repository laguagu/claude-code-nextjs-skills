---
title: Agents in AI SDK 7
description: Build ToolLoopAgent and WorkflowAgent agents with AI SDK 7.
---

# Agents in AI SDK 7

AI SDK 7 has two main agent paths:

| Use case | Agent |
| --- | --- |
| In-memory tool loop, normal request lifecycle | `ToolLoopAgent` from `ai` |
| Durable, resumable, workflow-backed execution | `WorkflowAgent` from `@ai-sdk/workflow` |
| Run an external agent runtime such as Claude Code or Codex | `HarnessAgent` from `@ai-sdk/harness/agent`; read [harnesses.md](harnesses.md) |

## ToolLoopAgent

Use `ToolLoopAgent` for ordinary app-server agents where losing in-memory state
on process restart is acceptable.

```ts
import { ToolLoopAgent, isStepCount, tool } from 'ai';
import { z } from 'zod';

export const agent = new ToolLoopAgent({
  model: __MODEL__,
  instructions: 'You are a helpful assistant.',
  tools: {
    weather: tool({
      description: 'Get weather for a city.',
      inputSchema: z.object({ city: z.string() }),
      contextSchema: z.object({ apiKey: z.string() }),
      execute: async ({ city }, { context }) => {
        return getWeather({ city, apiKey: context.apiKey });
      },
    }),
  },
  stopWhen: isStepCount(10),
});

const result = await agent.generate({
  prompt: 'Will I need an umbrella in Helsinki?',
  runtimeContext: { requestId: crypto.randomUUID() },
  toolsContext: {
    weather: { apiKey: process.env.WEATHER_API_KEY! },
  },
});
```

## Runtime and Tool Context

Use `runtimeContext` for shared state that affects the whole loop: tenant IDs,
feature flags, request IDs, user roles, or progress state. It is available to
`prepareStep`, lifecycle callbacks, results, and telemetry filters.

Use `toolsContext` for per-tool state. Each tool declares a `contextSchema` and
receives only its own validated `context` in `execute`, approval functions, and
tool callbacks. This keeps API keys and per-tool configuration scoped.

Do not put information the model must reason about into context; put that in
messages or `instructions`.

## Tool Approvals

Use `toolApproval` for AI SDK-executed tools that modify data, spend money, run
commands, send messages, or access private data.

```ts
const agent = new ToolLoopAgent({
  model: __MODEL__,
  tools: { runCommand },
  toolApproval: {
    runCommand: 'user-approval',
  },
});
```

Approval rules can return `not-applicable`, `approved`, `denied`, or
`user-approval`. Functions can inspect parsed tool input, `runtimeContext`, and
tool context.

For browser or client-controlled chat histories, use
`experimental_toolApprovalSecret` with `generateText` or `streamText` for
sensitive tools so approvals are HMAC-signed and revalidated before execution.
Verify current docs before using it with agents; support differs by agent type.

## WorkflowAgent

Use `WorkflowAgent` when a run must survive process restarts, deploys,
interrupted streams, delayed approval, or workflow retries.

```ts
import { WorkflowAgent, type ModelCallStreamPart } from '@ai-sdk/workflow';
import { convertToModelMessages, isStepCount, tool, type UIMessage } from 'ai';
import { getWritable } from 'workflow';

export async function chat(messages: UIMessage[]) {
  'use workflow';

  const agent = new WorkflowAgent({
    model: __MODEL__,
    instructions: 'You are a support agent.',
    tools: { lookupCustomer },
  });

  const result = await agent.stream({
    messages: await convertToModelMessages(messages),
    writable: getWritable<ModelCallStreamPart>(),
    stopWhen: isStepCount(10),
  });

  return { messages: result.messages };
}
```

Important differences from `ToolLoopAgent`:

- `WorkflowAgent` uses `stream()`; it does not expose `generate()`.
- It writes `ModelCallStreamPart` chunks to a workflow writable.
- Convert to UI chunks at the route boundary with
  `createModelCallToUIChunkTransform()`.
- Mark durable tool functions with `'use step'`.
- Workflow tool approval uses tool-level `needsApproval`, not `toolApproval`.
- Keep `runtimeContext` and `toolsContext` serializable because workflow state
  may be persisted and replayed.

## Type Safety

For `ToolLoopAgent`, export the inferred UI message type:

```ts
import type { InferAgentUIMessage } from 'ai';

export type MyAgentUIMessage = InferAgentUIMessage<typeof agent>;
```

For `WorkflowAgent`, use the workflow helper:

```ts
import type { InferWorkflowAgentUIMessage } from '@ai-sdk/workflow';

export type MyWorkflowMessage = InferWorkflowAgentUIMessage<typeof agent>;
```

## Gotchas

- AI SDK 7 renamed `stepCountIs` to `isStepCount`.
- Use `instructions`, not top-level `system`.
- `prepareStep` instruction and message overrides carry forward across later
  steps unless replaced.
- `result.usage` and top-level result arrays now aggregate all steps; use
  `finalStep` for previous final-step-only behavior.
- Workflow lifecycle callback names have changed across docs and package types.
  Check installed `@ai-sdk/workflow` types before renaming callback fields.
