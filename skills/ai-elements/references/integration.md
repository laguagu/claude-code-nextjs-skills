# AI SDK Integration

How to integrate AI Elements with Vercel AI SDK.

## useChat Hook

The core hook for chat functionality.

```tsx
'use client';
import { useChat } from '@ai-sdk/react';

export function Chat() {
  const {
    messages,      // UIMessage[] - message history
    sendMessage,   // Send new message
    status,        // ChatStatus: 'ready' | 'submitted' | 'streaming' | 'error'
    regenerate,    // Regenerate last assistant message
    error,         // Error object if status === 'error'
  } = useChat();

  // ...
}
```

### ChatStatus Values

| Status | Description | UI Pattern |
|--------|-------------|------------|
| `ready` | Ready for input | Enable submit |
| `submitted` | Request sent | Show Loader |
| `streaming` | Receiving response | Show streaming indicators |
| `error` | Request failed | Show error, enable retry |

## UIMessage Structure

Messages have `role` and `parts` array:

```typescript
type UIMessage = {
  id: string;
  role: 'user' | 'assistant';
  parts: UIMessagePart[];
};

type UIMessagePart =
  | { type: 'text'; text: string }
  | { type: 'reasoning'; text: string }
  | { type: 'source-url'; url: string; title?: string }
  | { type: 'tool-invocation'; toolName: string; input: unknown; state: ToolState }
  | { type: 'tool-result'; toolName: string; output: unknown; errorText?: string }
  | { type: 'file'; url: string; mediaType: string; filename?: string };
```

## Message Parts Rendering

Switch on `part.type` to render appropriate components:

```tsx
{messages.map((message) => (
  <div key={message.id}>
    {message.parts.map((part, i) => {
      switch (part.type) {
        case 'text':
          return (
            <Message key={i} from={message.role}>
              <MessageContent>
                <MessageResponse>{part.text}</MessageResponse>
              </MessageContent>
            </Message>
          );

        case 'reasoning':
          return (
            <Reasoning
              key={i}
              isStreaming={status === 'streaming' && isLastPart(message, i)}
            >
              <ReasoningTrigger />
              <ReasoningContent>{part.text}</ReasoningContent>
            </Reasoning>
          );

        case 'source-url':
          return (
            <Source key={i} href={part.url} title={part.title} />
          );

        default:
          // Handle tool-* types
          if (part.type.startsWith('tool-')) {
            return (
              <Tool key={i}>
                <ToolHeader type={part.type} state={part.state} title={part.toolName} />
                <ToolContent>
                  <ToolInput input={part.input} />
                  <ToolOutput output={part.output} errorText={part.errorText} />
                </ToolContent>
              </Tool>
            );
          }
          return null;
      }
    })}
  </div>
))}
```

## API Route Pattern

### Basic Route

```typescript
// app/api/chat/route.ts
import { streamText, UIMessage, convertToModelMessages } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';

export const maxDuration = 30;

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json();

  const result = streamText({
    model: anthropic('claude-sonnet-4-5'),
    messages: convertToModelMessages(messages),
    system: 'You are a helpful assistant.',
  });

  return result.toUIMessageStreamResponse({
    sendSources: true,
    sendReasoning: true,
  });
}
```

### With Dynamic Model Selection

```typescript
export async function POST(req: Request) {
  const {
    messages,
    model,
    webSearch,
  }: {
    messages: UIMessage[];
    model: string;
    webSearch: boolean;
  } = await req.json();

  const result = streamText({
    // Use different model for web search
    model: webSearch ? 'perplexity/sonar' : model,
    messages: convertToModelMessages(messages),
    system: 'You are a helpful assistant.',
  });

  return result.toUIMessageStreamResponse({
    sendSources: true,
    sendReasoning: true,
  });
}
```

### toUIMessageStreamResponse Options

| Option | Type | Description |
|--------|------|-------------|
| `sendSources` | `boolean` | Include source-url parts |
| `sendReasoning` | `boolean` | Include reasoning parts |

## Sending Messages with Options

```tsx
const { sendMessage } = useChat();

// Basic text message
sendMessage({ text: 'Hello!' });

// With file attachments
sendMessage({
  text: 'What is in this image?',
  files: [{ type: 'file', url: dataUrl, mediaType: 'image/png' }],
});

// With custom body options
sendMessage(
  { text: 'Search the web for this' },
  {
    body: {
      model: 'perplexity/sonar',
      webSearch: true,
    },
  }
);
```

## File Attachment Flow

### Client-side (PromptInput)

```tsx
const handleSubmit = async (message: PromptInputMessage) => {
  // message.files are FileUIPart[] with blob URLs
  // PromptInput automatically converts blob URLs to data URLs

  sendMessage({
    text: message.text,
    files: message.files, // Already converted to data URLs
  });
};
```

### Server-side Processing

```typescript
// Files are in message parts
const messages = convertToModelMessages(uiMessages);
// Files are automatically handled by AI SDK
```

## Error Handling

```tsx
const { error, status } = useChat();

{status === 'error' && (
  <Alert variant="destructive">
    <AlertDescription>
      {error?.message || 'An error occurred'}
    </AlertDescription>
  </Alert>
)}
```

## Regenerate Last Response

```tsx
const { regenerate } = useChat();

<MessageAction
  label="Retry"
  onClick={() => regenerate()}
>
  <RefreshCcwIcon className="size-3" />
</MessageAction>
```

## MCP Server Setup

AI Elements provides an MCP server for component documentation.

### Claude Code

```bash
claude mcp add --transport http ai-elements https://registry.ai-sdk.dev/api/mcp
```

### Cursor / Other Tools

```json
// .cursor/mcp.json or equivalent
{
  "mcpServers": {
    "ai-elements": {
      "command": "bunx",
      "args": ["--bun", "mcp-remote", "https://registry.ai-sdk.dev/api/mcp"]
    }
  }
}
```

### Usage

After setup, ask your AI assistant:
- "What AI Elements components are available?"
- "Show me how to use PromptInput with file attachments"
- "Help me create an AI chat layout"

## Provider Setup

### AI Gateway (Recommended)

```bash
# .env.local
AI_GATEWAY_API_KEY=your_key_here
```

AI Gateway provides:
- $5/month free usage
- Unified API key for multiple providers
- Get key at: https://ai-gateway.dev

### Direct Provider Setup

```bash
# .env.local
ANTHROPIC_API_KEY=your_key
OPENAI_API_KEY=your_key
```

## Dependencies

```bash
bun add ai @ai-sdk/react @ai-sdk/anthropic zod
```

| Package | Purpose |
|---------|---------|
| `ai` | Core AI SDK (streamText, UIMessage, etc.) |
| `@ai-sdk/react` | React hooks (useChat) |
| `@ai-sdk/anthropic` | Anthropic provider |
| `zod` | Schema validation |
