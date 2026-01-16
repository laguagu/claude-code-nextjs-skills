# UI Hooks & Components

## useChat Hook

```typescript
"use client";
import { useChat } from "@ai-sdk/react";

export function Chat() {
  const {
    messages,
    sendMessage,
    status,
    error,
    stop,
    regenerate,
    setMessages,
    clearError,
  } = useChat();

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
          const input = e.currentTarget.elements.namedItem("input") as HTMLInputElement;
          sendMessage(input.value);
          input.value = "";
        }}
      >
        <input name="input" placeholder="Type a message..." />
        <button type="submit" disabled={status !== "ready"}>
          Send
        </button>
      </form>
    </div>
  );
}
```

## useChat Parameters

| Parameter               | Type            | Description                             |
| ----------------------- | --------------- | --------------------------------------- |
| `id`                    | `string`        | Unique chat identifier                  |
| `messages`              | `UIMessage[]`   | Initial messages                        |
| `transport`             | `ChatTransport` | Custom transport (default: `/api/chat`) |
| `onToolCall`            | `function`      | Called when tool call received          |
| `onFinish`              | `function`      | Called when response finished           |
| `onError`               | `function`      | Error callback                          |
| `sendAutomaticallyWhen` | `function`      | Condition for auto-submitting messages  |
| `resume`                | `boolean`       | Enable stream resumption for recovery   |

## useChat Return Values

| Property        | Type                                               | Description               |
| --------------- | -------------------------------------------------- | ------------------------- |
| `messages`      | `UIMessage[]`                                      | Current messages          |
| `status`        | `'submitted' \| 'streaming' \| 'ready' \| 'error'` | Chat status               |
| `error`         | `Error \| undefined`                               | Error if any              |
| `sendMessage`   | `function`                                         | Send new message          |
| `regenerate`    | `function`                                         | Regenerate last response  |
| `stop`          | `function`                                         | Stop streaming            |
| `setMessages`   | `function`                                         | Update messages locally   |
| `resumeStream`  | `function`                                         | Resume interrupted stream |
| `addToolOutput` | `function`                                         | Provide tool result       |
| `clearError`    | `function`                                         | Clear current error       |

## Status Values

- `submitted` - Message sent, awaiting response
- `streaming` - Response is streaming
- `ready` - Ready for new message
- `error` - An error occurred

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

// Tool call
type ToolUIPart = {
  type: `tool-${NAME}`;
  toolCallId: string;
  state:
    | "input-streaming"
    | "input-available"
    | "output-available"
    | "output-error";
  input: ToolInput;
  output?: ToolOutput;
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

type SourceDocumentUIPart = {
  type: "source-document";
  documentId: string;
  content?: string;
};

// Agent workflow boundaries
type StepStartUIPart = {
  type: "step-start";
  stepId: string;
};

// Custom data
type DataUIPart = {
  type: string; // Custom type
  data: unknown;
};
```

## Typed Messages with Agent

```typescript
import { useChat } from "@ai-sdk/react";
import type { MyAgentUIMessage } from "@/agents/my-agent";

export function Chat() {
  const { messages } = useChat<MyAgentUIMessage>();

  return (
    <div>
      {messages.map((message) =>
        message.parts.map((part, i) => {
          switch (part.type) {
            case "text":
              return <p key={i}>{part.text}</p>;
            case "tool-weather":
              return <WeatherCard key={i} data={part.output} />;
            case "reasoning":
              return (
                <details key={i}>
                  <summary>Thinking...</summary>
                  {part.text}
                </details>
              );
          }
        })
      )}
    </div>
  );
}
```

## Custom Transport

```typescript
import { useChat, DefaultChatTransport } from "@ai-sdk/react";

const { messages, sendMessage } = useChat({
  transport: new DefaultChatTransport({
    api: "/api/custom-chat",
    headers: {
      Authorization: `Bearer ${token}`,
    },
  }),
});
```

## Message Persistence

### Server-Side

```typescript
// app/api/chat/route.ts
import { streamText, convertToModelMessages } from "ai";
import { saveChat } from "@/lib/chat-storage";

export async function POST(req: Request) {
  const { messages, chatId } = await req.json();

  const result = streamText({
    model: anthropic("claude-sonnet-4-5"),
    messages: await convertToModelMessages(messages),
  });

  result.consumeStream(); // Ensure completion even if client disconnects

  return result.toUIMessageStreamResponse({
    originalMessages: messages,
    onFinish: ({ messages }) => {
      saveChat({ chatId, messages });
    },
  });
}
```

### Client-Side with Initial Messages

```typescript
export default function ChatPage({ params }: { params: { id: string } }) {
  const initialMessages = await loadChat(params.id);

  return <Chat id={params.id} initialMessages={initialMessages} />;
}

function Chat({ id, initialMessages }: { id: string; initialMessages: UIMessage[] }) {
  const { messages, sendMessage } = useChat({
    id,
    messages: initialMessages,
  });

  // ...
}
```

## Streaming Protocols

### Data Stream (Default)

Uses Server-Sent Events with structured message format:

```typescript
// Default behavior
return result.toUIMessageStreamResponse();
```

### Text Stream

For simple text-only responses:

```typescript
const { messages } = useChat({
  streamProtocol: "text",
});
```

## Tool Handling in UI

```typescript
const { messages, addToolOutput } = useChat({
  onToolCall: async ({ toolCall }) => {
    if (toolCall.toolName === "confirm") {
      const confirmed = await showConfirmDialog(toolCall.args.message);
      addToolOutput({
        toolCallId: toolCall.toolCallId,
        output: { confirmed },
      });
    }
  },
});
```
