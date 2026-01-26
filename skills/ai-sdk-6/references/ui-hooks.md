# UI Hooks & Components

## useChat Hook

```typescript
"use client";
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";
import { useState } from "react";

export function Chat() {
  const [input, setInput] = useState("");
  const {
    messages,
    sendMessage,
    status,
    error,
    stop,
    regenerate,
    setMessages,
    clearError,
    addToolOutput,
    addToolApprovalResponse,
  } = useChat({
    transport: new DefaultChatTransport({
      api: "/api/chat",
    }),
  });

  return (
    <div>
      {messages.map((message) => (
        <div key={message.id}>
          <strong>{message.role}:</strong>
          {message.parts.map((part, i) =>
            part.type === "text" ? <p key={i}>{part.text}</p> : null
          )}
        </div>
      ))}

      <form
        onSubmit={(e) => {
          e.preventDefault();
          if (input.trim()) {
            sendMessage({ text: input });
            setInput("");
          }
        }}
      >
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          disabled={status !== "ready"}
        />
        <button type="submit" disabled={status !== "ready"}>
          Send
        </button>
      </form>
    </div>
  );
}
```

> **v6 Note**: `useChat` no longer manages input state internally. Use `useState` for controlled inputs.

## useChat Parameters

| Parameter               | Type            | Description                                      |
| ----------------------- | --------------- | ------------------------------------------------ |
| `id`                    | `string`        | Unique chat identifier                           |
| `messages`              | `UIMessage[]`   | Initial messages                                 |
| `transport`             | `ChatTransport` | Transport for API communication (see below)      |
| `onToolCall`            | `function`      | Called when tool call received                   |
| `onFinish`              | `function`      | Called when response finished                    |
| `onError`               | `function`      | Error callback                                   |
| `onData`                | `function`      | Called when data part received                   |
| `sendAutomaticallyWhen` | `function`      | Condition for auto-submitting (e.g., tool calls) |
| `resume`                | `boolean`       | Enable stream resumption for recovery            |
| `experimental_throttle` | `number`        | Throttle UI updates (ms)                         |

## useChat Return Values

| Property                  | Type                                               | Description                  |
| ------------------------- | -------------------------------------------------- | ---------------------------- |
| `id`                      | `string`                                           | Chat ID                      |
| `messages`                | `UIMessage[]`                                      | Current messages             |
| `status`                  | `'submitted' \| 'streaming' \| 'ready' \| 'error'` | Chat status                  |
| `error`                   | `Error \| undefined`                               | Error if any                 |
| `sendMessage`             | `function`                                         | Send new message             |
| `regenerate`              | `function`                                         | Regenerate last response     |
| `stop`                    | `function`                                         | Stop streaming               |
| `setMessages`             | `function`                                         | Update messages locally      |
| `resumeStream`            | `function`                                         | Resume interrupted stream    |
| `addToolOutput`           | `function`                                         | Provide tool result          |
| `addToolApprovalResponse` | `function`                                         | Approve/deny tool execution  |
| `clearError`              | `function`                                         | Clear current error          |

## Status Values

- `submitted` - Message sent, awaiting response start
- `streaming` - Response is actively streaming
- `ready` - Ready for new message
- `error` - An error occurred

## Transport Options

### DefaultChatTransport (Recommended)

```typescript
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";

const { messages, sendMessage } = useChat({
  transport: new DefaultChatTransport({
    api: "/api/chat",
    headers: { Authorization: `Bearer ${token}` },
    body: { user_id: "123" },
    credentials: "same-origin",
  }),
});
```

### Dynamic Configuration

```typescript
transport: new DefaultChatTransport({
  api: "/api/chat",
  headers: () => ({ Authorization: `Bearer ${getAuthToken()}` }),
  body: () => ({ sessionId: getCurrentSessionId() }),
}),
```

### Custom Request Preparation

```typescript
transport: new DefaultChatTransport({
  api: "/api/chat",
  prepareSendMessagesRequest: ({ id, messages, trigger }) => {
    if (trigger === "submit-user-message") {
      return { body: { id, message: messages[messages.length - 1] } };
    }
    return { body: { id, messages } };
  },
}),
```

### TextStreamChatTransport

For plain text streams without tool support:

```typescript
import { TextStreamChatTransport } from "ai";

const { messages } = useChat({
  transport: new TextStreamChatTransport({
    api: "/api/chat",
  }),
});
```

### DirectChatTransport

For direct agent communication without HTTP:

```typescript
import { DirectChatTransport, ToolLoopAgent } from "ai";

const agent = new ToolLoopAgent({
  model: anthropic("claude-sonnet-4-5"),
  instructions: "You are a helpful assistant.",
});

const { messages, sendMessage } = useChat({
  transport: new DirectChatTransport({ agent }),
});
```

## UIMessage Type

```typescript
interface UIMessage<METADATA, DATA_PARTS, TOOLS> {
  id: string;
  role: "system" | "user" | "assistant";
  metadata?: METADATA;
  parts: Array<UIMessagePart>;
}
```

### Message Part Types

```typescript
// Text content
type TextUIPart = {
  type: "text";
  text: string;
  state?: "streaming" | "done";
};

// Tool call (typed by tool name)
type ToolUIPart = {
  type: `tool-${NAME}`;
  toolCallId: string;
  state:
    | "input-streaming"
    | "input-available"
    | "approval-requested"
    | "output-available"
    | "output-error";
  input: ToolInput;
  output?: ToolOutput;
  errorText?: string;
  approval?: { id: string };
};

// Dynamic tool (unknown at compile time)
type DynamicToolUIPart = {
  type: "dynamic-tool";
  toolName: string;
  toolCallId: string;
  state: "input-streaming" | "input-available" | "output-available" | "output-error";
  input: unknown;
  output?: unknown;
  errorText?: string;
};

// Reasoning (for models that support it)
type ReasoningUIPart = {
  type: "reasoning";
  text: string;
  state?: "streaming" | "done";
};

// File attachment
type FileUIPart = {
  type: "file";
  mediaType: string;
  filename?: string;
  url: string;
};

// Source references (RAG)
type SourceUrlUIPart = {
  type: "source-url";
  url: string;
  title?: string;
};

// Step boundaries (multi-step)
type StepStartUIPart = {
  type: "step-start";
  stepId: string;
};
```

## Tool Handling

### Client-Side Tool Execution

```typescript
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport, lastAssistantMessageIsCompleteWithToolCalls } from "ai";

const { messages, sendMessage, addToolOutput } = useChat({
  transport: new DefaultChatTransport({ api: "/api/chat" }),

  // Auto-submit when all tool results available
  sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithToolCalls,

  async onToolCall({ toolCall }) {
    // IMPORTANT: Check dynamic first for type narrowing
    if (toolCall.dynamic) {
      return;
    }

    if (toolCall.toolName === "getLocation") {
      const cities = ["Helsinki", "Tokyo", "New York"];
      // No await - avoids potential deadlocks
      addToolOutput({
        tool: "getLocation",
        toolCallId: toolCall.toolCallId,
        output: cities[Math.floor(Math.random() * cities.length)],
      });
    }
  },
});
```

### Tool Error Handling

```typescript
async onToolCall({ toolCall }) {
  if (toolCall.dynamic) return;

  if (toolCall.toolName === "fetchData") {
    try {
      const data = await fetchData(toolCall.input);
      addToolOutput({
        tool: "fetchData",
        toolCallId: toolCall.toolCallId,
        output: data,
      });
    } catch (err) {
      addToolOutput({
        tool: "fetchData",
        toolCallId: toolCall.toolCallId,
        state: "output-error",
        errorText: "Failed to fetch data",
      });
    }
  }
},
```

### Tool Approval (needsApproval)

```typescript
const { messages, addToolApprovalResponse } = useChat({
  sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithApprovalResponses,
});

// In render:
{message.parts.map((part) => {
  if (part.type === "tool-deleteFile" && part.state === "approval-requested") {
    return (
      <div key={part.toolCallId}>
        <p>Delete {part.input.filename}?</p>
        <button onClick={() => addToolApprovalResponse({
          id: part.approval.id,
          approved: true,
        })}>
          Approve
        </button>
        <button onClick={() => addToolApprovalResponse({
          id: part.approval.id,
          approved: false,
        })}>
          Deny
        </button>
      </div>
    );
  }
})}
```

### Rendering Tool Parts

```typescript
{messages.map((message) =>
  message.parts.map((part, i) => {
    switch (part.type) {
      case "text":
        return <p key={i}>{part.text}</p>;

      case "tool-weather":
        switch (part.state) {
          case "input-streaming":
            return <div key={i}>Loading...</div>;
          case "input-available":
            return <div key={i}>Getting weather for {part.input.city}...</div>;
          case "output-available":
            return <WeatherCard key={i} data={part.output} />;
          case "output-error":
            return <div key={i}>Error: {part.errorText}</div>;
        }
        break;

      case "dynamic-tool":
        return (
          <div key={i}>
            <strong>{part.toolName}</strong>
            <pre>{JSON.stringify(part.output ?? part.input, null, 2)}</pre>
          </div>
        );

      case "reasoning":
        return (
          <details key={i}>
            <summary>Thinking...</summary>
            {part.text}
          </details>
        );

      case "step-start":
        return i > 0 ? <hr key={i} /> : null;
    }
  })
)}
```

## Message Persistence

### consumeStream - Handling Client Disconnects

By default, `streamText` uses backpressure - when client disconnects (browser tab closed, network issue), the LLM stream is aborted and `onFinish` never fires. This leaves conversations in a broken state.

**Solution**: Call `result.consumeStream()` (without await) to ensure the stream completes and `onFinish` triggers even after client disconnect.

```typescript
// app/api/chat/route.ts
import { streamText, convertToModelMessages, UIMessage } from "ai";
import { saveChat } from "@/lib/chat-storage";

export async function POST(req: Request) {
  const { messages, chatId }: { messages: UIMessage[]; chatId: string } =
    await req.json();

  const result = streamText({
    model: anthropic("claude-sonnet-4-5"),
    messages: await convertToModelMessages(messages),
  });

  // IMPORTANT: Consume stream to ensure completion even if client disconnects
  // This removes backpressure - stream runs to completion regardless of client state
  result.consumeStream(); // no await!

  return result.toUIMessageStreamResponse({
    originalMessages: messages,
    onFinish: ({ messages }) => {
      // This now fires even if client disconnected mid-stream
      saveChat({ chatId, messages });
    },
  });
}
```

> **Note**: When client reloads after disconnect, chat restores from storage. For production, also track request state (in-progress/complete) to handle page reloads during active streaming.

### Server-Side with createUIMessageStream

```typescript
import {
  createUIMessageStream,
  createUIMessageStreamResponse,
  streamText,
  convertToModelMessages,
} from "ai";

export async function POST(req: Request) {
  const { messages } = await req.json();

  return createUIMessageStreamResponse({
    stream: createUIMessageStream({
      execute: async ({ writer }) => {
        // Write sources first
        writer.write({
          type: "source-url",
          sourceId: "src-1",
          url: "https://example.com",
          title: "Example Source",
        });

        // Stream LLM response
        const result = streamText({
          model: anthropic("claude-sonnet-4-5"),
          messages: await convertToModelMessages(messages),
        });

        writer.merge(result.toUIMessageStream());
      },
    }),
  });
}
```

### Client-Side with Initial Messages

```typescript
// app/chat/[id]/page.tsx
export default async function ChatPage({ params }: { params: { id: string } }) {
  const initialMessages = await loadChat(params.id);
  return <Chat id={params.id} initialMessages={initialMessages} />;
}

// components/chat.tsx
function Chat({ id, initialMessages }: { id: string; initialMessages: UIMessage[] }) {
  const [input, setInput] = useState("");
  const { messages, sendMessage } = useChat({
    id,
    messages: initialMessages,
    transport: new DefaultChatTransport({ api: "/api/chat" }),
  });
  // ...
}
```

### Sending Only Last Message

```typescript
// Client
transport: new DefaultChatTransport({
  api: "/api/chat",
  prepareSendMessagesRequest({ messages, id }) {
    return { body: { message: messages[messages.length - 1], id } };
  },
}),

// Server
export async function POST(req: Request) {
  const { message, id } = await req.json();
  const previousMessages = await loadChat(id);
  const messages = [...previousMessages, message];

  const result = streamText({
    model: anthropic("claude-sonnet-4-5"),
    messages: await convertToModelMessages(messages),
  });

  return result.toUIMessageStreamResponse({
    originalMessages: messages,
    onFinish: ({ messages }) => saveChat({ chatId: id, messages }),
  });
}
```

### Validating Messages

```typescript
import { validateUIMessages, TypeValidationError } from "ai";

export async function POST(req: Request) {
  const { message, id } = await req.json();
  const previousMessages = await loadChat(id);

  try {
    const validatedMessages = await validateUIMessages({
      messages: [...previousMessages, message],
      tools,           // if using tools
      metadataSchema,  // if using custom metadata
    });

    const result = streamText({
      model: anthropic("claude-sonnet-4-5"),
      messages: await convertToModelMessages(validatedMessages),
    });

    return result.toUIMessageStreamResponse({ originalMessages: validatedMessages });
  } catch (error) {
    if (error instanceof TypeValidationError) {
      console.error("Validation failed:", error);
      // Handle invalid messages
    }
    throw error;
  }
}
```

## Message Metadata

### Server-Side

```typescript
return result.toUIMessageStreamResponse({
  messageMetadata: ({ part }) => {
    if (part.type === "start") {
      return { createdAt: Date.now(), model: "gpt-5-mini" };
    }
    if (part.type === "finish") {
      return { totalTokens: part.totalUsage.totalTokens };
    }
  },
});
```

### Client-Side

```typescript
{messages.map((message) => (
  <div key={message.id}>
    {message.metadata?.createdAt && (
      <span>{new Date(message.metadata.createdAt).toLocaleTimeString()}</span>
    )}
    {message.metadata?.totalTokens && (
      <span>{message.metadata.totalTokens} tokens</span>
    )}
  </div>
))}
```

## Streaming Options

### Enable Reasoning

```typescript
return result.toUIMessageStreamResponse({
  sendReasoning: true,
});
```

### Enable Sources

```typescript
return result.toUIMessageStreamResponse({
  sendSources: true,
});
```

### Error Handling

```typescript
return result.toUIMessageStreamResponse({
  onError: (error) => {
    if (error instanceof Error) return error.message;
    return "An error occurred";
  },
});
```

## Type Inference for Tools

```typescript
import { InferUITools, UIMessage, UIDataTypes, ToolSet } from "ai";

const tools = {
  weather: tool({
    description: "Get weather",
    inputSchema: z.object({ city: z.string() }),
    execute: async ({ city }) => ({ temp: 22, conditions: "sunny" }),
  }),
} satisfies ToolSet;

type MyUITools = InferUITools<typeof tools>;
type MyUIMessage = UIMessage<never, UIDataTypes, MyUITools>;

// Use in hook
const { messages } = useChat<MyUIMessage>({
  transport: new DefaultChatTransport({ api: "/api/chat" }),
});
```
