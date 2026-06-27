---
title: AI SDK 7 UI Hooks
description: useChat, UIMessage streams, tool parts, approvals, harness UI, and workflow UI.
---

# AI SDK 7 UI Hooks

Use `@ai-sdk/react` for React UI and `DefaultChatTransport` from `ai` for
standard chat routes. `useChat` does not own input state; manage form state in
the component.

## Basic useChat

```tsx
'use client';

import { useChat } from '@ai-sdk/react';
import { DefaultChatTransport } from 'ai';
import { useState } from 'react';

export function Chat() {
  const [input, setInput] = useState('');
  const { messages, sendMessage, status } = useChat({
    transport: new DefaultChatTransport({ api: '/api/chat' }),
  });

  return (
    <form
      onSubmit={event => {
        event.preventDefault();
        if (input.trim()) {
          sendMessage({ text: input });
          setInput('');
        }
      }}
    >
      <input
        value={input}
        onChange={event => setInput(event.target.value)}
        disabled={status !== 'ready'}
      />
      <button disabled={status !== 'ready'}>Send</button>
    </form>
  );
}
```

## Typed Tool Parts

Render typed tool parts (`tool-{toolName}`) and check state before reading
input/output:

```tsx
if (
  part.type === 'tool-getWeather' &&
  (part.state === 'input-available' || part.state === 'output-available')
) {
  return <div>{part.input.location}</div>;
}

if (part.type === 'tool-getWeather' && part.state === 'output-available') {
  return <div>{part.output.summary}</div>;
}
```

Use `isToolUIPart(part)` for generic rendering when you do not need the typed
tool shape.

## Tool Approvals

Approval requests arrive as tool parts with `state: 'approval-requested'`.
Respond only to manual approvals:

```tsx
const { messages, addToolApprovalResponse } = useChat({
  sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithApprovalResponses,
});

// inside render
if (part.type === 'tool-runCommand' && part.state === 'approval-requested') {
  return (
    <button
      onClick={() =>
        addToolApprovalResponse({
          id: part.approval.id,
          approved: true,
        })
      }
    >
      Approve
    </button>
  );
}
```

## HarnessAgent UI

Harness UI routes must manage sessions. Do not rely on replaying all UI messages
as model context.

Server route outline:

```ts
import {
  convertToModelMessages,
  createUIMessageStreamResponse,
  toUIMessageStream,
  type UIMessage,
} from 'ai';
import { agent } from './agent';

export async function POST(request: Request) {
  const body: { id?: string; messages: UIMessage[] } = await request.json();
  if (!body.id) throw new Error('Missing chat id');

  const session = await resumeOrCreateSession({
    agent,
    chatId: body.id,
  });

  const result = await agent.stream({
    session,
    messages: await convertToModelMessages(body.messages),
  });

  return createUIMessageStreamResponse({
    stream: toUIMessageStream({
      stream: result.stream,
      onEnd: async () => {
        await detachAndPersist({ chatId: body.id!, session });
      },
    }),
  });
}
```

Render text, reasoning, typed harness tools (`tool-bash`, `tool-read`, etc.),
and `dynamic-tool` parts. Dynamic parts can represent file changes or
compaction.

## WorkflowAgent UI

Use `WorkflowChatTransport` when workflow streams can be interrupted and need
reconnection. The POST endpoint should return an `x-workflow-run-id` header, and
a GET endpoint at `{api}/{runId}/stream` should return the readable stream from
the workflow runtime.

At the response boundary, convert workflow model chunks:

```ts
import { createModelCallToUIChunkTransform } from '@ai-sdk/workflow';
import { createUIMessageStreamResponse } from 'ai';

return createUIMessageStreamResponse({
  stream: run.readable.pipeThrough(createModelCallToUIChunkTransform()),
});
```

## Gotchas

- `input`, `handleInputChange`, and `handleSubmit` are legacy `useChat` patterns.
- `tool-invocation`, `part.args`, and `part.result` are legacy UI shapes.
- For v7 `streamText`, prefer stateless stream helpers over result helper
  methods.
- Store `UIMessage[]` as the source of truth for UI rendering. Do not persist
  only `ModelMessage[]` if the UI must render the conversation later.
