---
name: ai-sdk-7
description: "Vercel AI SDK v7 development and migration. Use when building or upgrading AI SDK 7 apps, especially ToolLoopAgent, WorkflowAgent, HarnessAgent, Claude Code/Codex/Pi harnesses, runtimeContext, toolsContext, toolApproval, telemetry, reasoning, file or skill uploads, realtime, video generation, or v6-to-v7 breaking changes. For AI SDK v6 code use ai-sdk-6; for version discovery and general doc lookup use ai-sdk."
compatibility: "TypeScript/JavaScript projects using AI SDK 7; Node.js >=22; AI SDK packages are ESM-only."
---

# AI SDK 7 implementation and migration

Apply this skill to `ai@7`; use `ai-sdk` to resolve unknown versions and
`ai-sdk-6` for v6 maintenance. Match provider and UI package versions to the
project. AI SDK 7 requires Node.js 22+ and AI SDK packages are ESM-only.

Read the resolved `ai/docs/`, provider docs and installed source/types first;
each `ai-sdk.dev/docs/...` link in this skill has an offline copy under `ai/docs/`
(path mapping in `ai-sdk`). Harness, WorkflowAgent and migration guides live
in `ai/docs/03-ai-sdk-harnesses/`, `03-agents/07-workflow-agent.mdx` and
`08-migration-guides/23-migration-guide-7-0.mdx`; the companion packages ship
only types. Use [official docs](https://ai-sdk.dev/docs) or the matching
repository tag when local docs are unavailable. Experimental package APIs need
a fresh check before adding long-lived wrappers.

| Need | Entry point |
| --- | --- |
| In-memory agent loop | `ToolLoopAgent` from `ai` |
| Durable agent | `WorkflowAgent` from `@ai-sdk/workflow` + `workflow` 5 |
| Claude Code/Codex/Pi runtime | `HarnessAgent` from `@ai-sdk/harness/agent` + adapter + sandbox package |
| OpenTelemetry | `registerTelemetry(new OpenTelemetry())`, `@ai-sdk/otel` |
| Stalled calls | `timeout`: ms or `{ totalMs, stepMs, firstChunkMs, chunkMs, toolMs }` |

## Important boundaries

- Text functions and ToolLoopAgent use `instructions`; loop limits use
  `isStepCount`. Core, agent and server UI-stream helpers use `onEnd`/`onStepEnd`
  (`onFinish` remains a deprecated alias); client `useChat`/`Chat` keeps
  `onFinish`.
- `prepareStep` instruction/message overrides carry forward. Results such as
  `usage` and tool arrays aggregate all steps; `finalStep` preserves final-step
  access, and is awaited for streams.
- Use `runtimeContext` for server loop state and schema-validated
  `toolsContext` for per-tool state. Neither is model-visible merely by being
  context.
- Approval, persistence and lifecycle differ across ToolLoopAgent,
  WorkflowAgent, HarnessAgent and provider-executed tools. Choose the runtime
  for the actual durability/permission requirements.
- Resolve model IDs and capabilities from the configured provider. Avoid
  overlapping reasoning settings: provider options can override top-level
  `reasoning`.

## Core shape

Checked with `ai@7.0.124`, `@ai-sdk/react@4.0.127`, `zod@4.6.5`, React 19 and
TypeScript 5.9: `tsc --noEmit`, plus a mock-model run through one tool step and
the follow-up answer. A string model resolves through the AI Gateway.

```ts
// app/api/chat/route.ts
import { convertToModelMessages, createUIMessageStreamResponse, isStepCount, streamText, tool,
  toUIMessageStream, validateUIMessages, type InferUITools, type UIDataTypes, type UIMessage } from 'ai';
import { z } from 'zod';

const tools = {
  weather: tool({
    inputSchema: z.object({ city: z.string() }),
    execute: async ({ city }) => ({ city, celsius: 21 }),
  }),
};
export type ChatMessage = UIMessage<never, UIDataTypes, InferUITools<typeof tools>>;

export async function POST(req: Request) {
  const { messages } = await req.json();
  const uiMessages = await validateUIMessages<ChatMessage>({ messages, tools });
  const result = streamText({
    model: 'provider/model-id', // configured gateway ID, or a provider instance
    instructions: 'Answer briefly.',
    messages: await convertToModelMessages(uiMessages),
    tools,
    stopWhen: isStepCount(5),
  });
  return createUIMessageStreamResponse({ stream: toUIMessageStream({ stream: result.stream }) });
}
```

```tsx
// app/page.tsx
'use client';
import { useChat } from '@ai-sdk/react';
import { DefaultChatTransport } from 'ai';
import type { ChatMessage } from './api/chat/route';

const transport = new DefaultChatTransport<ChatMessage>({ api: '/api/chat' });

export default function Chat() {
  const { messages, sendMessage, status } = useChat<ChatMessage>({ transport });
  return (
    <form action={(form) => void sendMessage({ text: String(form.get('text')) })}>
      {messages.map((m) => <div key={m.id}>{m.parts.map((part, i) =>
        part.type === 'text' ? <p key={i}>{part.text}</p>
        : part.type === 'tool-weather' && part.state === 'output-available'
          ? <p key={i}>{part.output.city}: {part.output.celsius} °C</p> : null)}</div>)}
      <input name="text" disabled={status === 'submitted' || status === 'streaming'} />
    </form>
  );
}
```

The v6 spellings (`system`, `stepCountIs`, `result.toUIMessageStreamResponse()`)
still compile in 7.0.124; `system` and the response method are deprecated.

## Read for the feature

- [Agents](references/agents.md): in-memory/durable execution and context.
- [Harnesses](references/harnesses.md): runtime-owned sessions and permissions.
- [Core functions](references/core-functions.md): output, stream and result contracts.
- [Tools](references/tools.md): approval boundaries, MCP Apps and sandbox handles.
- [UI hooks](references/ui-hooks.md): UI streams, approval and resumption.
- [Migration](references/migration-v6-to-v7.md): semantic changes and codemods.
- [Telemetry](references/telemetry.md): registration and data controls.
- [Media/files](references/media-and-files.md): provider references and capability gates.
- [Examples](references/examples.md): current official implementations.

Typecheck and exercise the changed multi-turn, tool, stream or resume path.
A successful compile does not prove approval policy or persistence behavior.
