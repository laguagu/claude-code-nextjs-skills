---
name: ai-sdk-6
description: Vercel AI SDK v6 development, for projects already on ai@6. Use when building or maintaining AI agents, chatbots, tool integrations, streaming apps, or structured output in a v6 codebase. New projects and ai@7 code use ai-sdk-7; an unknown version goes through ai-sdk. Covers ToolLoopAgent, useChat, generateText, streamText, tool approval, smoothStream, provider tools, MCP integration, and Output patterns.
---

# AI SDK 6 maintenance

Apply this skill only to `ai@6` projects. Resolve compatible provider and UI
packages from the existing manifest/lockfile. Use `ai-sdk` when the major is
unknown and `ai-sdk-7` for an authorized upgrade.

Read the resolved `ai/docs/`, provider docs and source/types for the exact minor
release. In a monorepo, resolve from the app using the dependency. Default web
docs and repository main can describe v7. `ai` bundles `docs/` from 6.0.32; the
tree mirrors the website paths (mapping in `ai-sdk`). If installed docs are
unavailable, select the `ai@<resolved-version>` tag in `vercel/ai` and read
`content/docs/`.
Feature links here use a checked [v6 documentation snapshot](https://github.com/vercel/ai/tree/ai%406.0.297/content/docs)
as a fallback; match the project's release when available. This tag selects
documentation, not an application dependency version.

## Boundaries that differ from old and new code

- Text functions use `system`; `ToolLoopAgent` uses `instructions`.
- Loop limits use `stopWhen: stepCountIs(...)`. Text functions default to one
  step (tool execution without a follow-up answer); `ToolLoopAgent` defaults
  to 20.
- `convertToModelMessages` is async; await it.
- Use text functions with `Output` for new schema output; legacy object
  functions are deprecated.
- Tools use `inputSchema`; SDK-executed approval is tool-level `needsApproval`.
  V6 does not know v7's `toolApproval`: unless a typecheck rejects it, it is
  ignored and the tool runs without approval.
- React `useChat` owns messages and stream status, not form input. Use the
  appropriate transport and UI-message response protocol.
- Core completion callbacks are `onFinish`; result `usage` is final-step usage,
  while `totalUsage` covers all steps.

Use a configured model verified for the actual provider. Typecheck and test a
multi-turn stream with relevant tool/approval/error states after integration changes.

## Core shape

Checked with `ai@6.0.298`, `@ai-sdk/react@3.0.301`, `zod@4.6.5`, React 19 and
TypeScript 5.9: `tsc --noEmit`, plus a mock-model run through one tool step and
the follow-up answer. A string model resolves through the AI Gateway. In v7,
`system`, `stepCountIs` and `result.toUIMessageStreamResponse()` become
`instructions`, `isStepCount` and
`createUIMessageStreamResponse({ stream: toUIMessageStream({ stream: result.stream }) })`.

```ts
// app/api/chat/route.ts
import { convertToModelMessages, stepCountIs, streamText, tool, validateUIMessages,
  type InferUITools, type UIDataTypes, type UIMessage } from 'ai';
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
    system: 'Answer briefly.',
    messages: await convertToModelMessages(uiMessages),
    tools,
    stopWhen: stepCountIs(5),
  });
  return result.toUIMessageStreamResponse();
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

## Read for the feature

- [Agents](references/agents.md): loop limits, call options and context.
- [Core functions](references/core-functions.md): output and stream contracts.
- [Tools](references/tools.md): execution, approval and typed states.
- [UI hooks](references/ui-hooks.md): transport, restoration and stream lifetime.
- [Middleware](references/middleware.md): provider interception.
- [MCP](references/mcp.md): transport and cleanup.
- [Workflows](references/workflows.md): when a loop needs explicit orchestration.
- [Examples](references/examples.md): version-matched official implementations.
