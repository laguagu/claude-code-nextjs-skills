# Agent Dashboard Templates

Templates for building agent-based AI applications with tool visualization.

## Basic Agent Setup

### Agent Definition

```typescript
// ai/assistant.ts
import { ToolLoopAgent, tool, stepCountIs } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { z } from 'zod';

export const assistantAgent = new ToolLoopAgent({
  model: anthropic('claude-sonnet-4-5'),
  instructions: `You are a helpful AI assistant with access to various tools.
    Use tools when needed to provide accurate information.
    Always explain what you're doing before using a tool.`,
  tools: {
    searchWeb: tool({
      description: 'Search the web for information',
      inputSchema: z.object({
        query: z.string().describe('Search query'),
      }),
      execute: async ({ query }) => {
        // Implement web search
        return { results: [`Result for: ${query}`] };
      },
    }),
    calculateMath: tool({
      description: 'Perform mathematical calculations',
      inputSchema: z.object({
        expression: z.string().describe('Math expression to evaluate'),
      }),
      execute: async ({ expression }) => {
        // Use mathjs for safe expression evaluation
        const { evaluate } = await import('mathjs');
        try {
          const result = evaluate(expression);
          return { result: String(result) };
        } catch {
          return { error: 'Invalid expression' };
        }
      },
    }),
    getCurrentTime: tool({
      description: 'Get the current date and time',
      inputSchema: z.object({}),
      execute: async () => {
        return { time: new Date().toISOString() };
      },
    }),
  },
  stopWhen: stepCountIs(20),
});
```

### API Route

```typescript
// app/api/chat/route.ts
import { createAgentUIStreamResponse } from 'ai';
import { assistantAgent } from '@/ai/assistant';

export const maxDuration = 30;

export async function POST(request: Request) {
  const { messages } = await request.json();

  return createAgentUIStreamResponse({
    agent: assistantAgent,
    uiMessages: messages,
    sendSources: true,
    includeUsage: true,
  });
}
```

---

## Dashboard Page with Tool Visualization

```tsx
// app/page.tsx
'use client';
import { useChat } from '@ai-sdk/react';
import {
  Conversation,
  ConversationContent,
  ConversationScrollButton,
} from '@/components/ai-elements/conversation';
import {
  Message,
  MessageContent,
  MessageResponse,
} from '@/components/ai-elements/message';
import {
  PromptInput,
  PromptInputBody,
  PromptInputTextarea,
  PromptInputFooter,
  PromptInputSubmit,
  type PromptInputMessage,
} from '@/components/ai-elements/prompt-input';
import {
  Tool,
  ToolHeader,
  ToolContent,
  ToolInput,
  ToolOutput,
} from '@/components/ai-elements/tool';
import {
  Reasoning,
  ReasoningTrigger,
  ReasoningContent,
} from '@/components/ai-elements/reasoning';
import { Loader } from '@/components/ai-elements/loader';
import { useState } from 'react';

export default function AgentDashboard() {
  const [input, setInput] = useState('');
  const { messages, sendMessage, status } = useChat();

  const handleSubmit = (message: PromptInputMessage) => {
    if (!message.text.trim()) return;
    sendMessage({ text: message.text });
    setInput('');
  };

  return (
    <div className="flex h-screen">
      {/* Sidebar */}
      <aside className="w-64 border-r bg-muted/50 p-4">
        <h2 className="mb-4 font-semibold">AI Assistant</h2>
        <div className="space-y-2 text-sm text-muted-foreground">
          <p>Available tools:</p>
          <ul className="ml-4 list-disc">
            <li>Web Search</li>
            <li>Calculator</li>
            <li>Current Time</li>
          </ul>
        </div>
      </aside>

      {/* Main Chat */}
      <main className="flex flex-1 flex-col">
        <Conversation className="flex-1 p-4">
          <ConversationContent>
            {messages.map((message) => (
              <div key={message.id} className="space-y-2">
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
                          isStreaming={
                            status === 'streaming' &&
                            message.id === messages.at(-1)?.id
                          }
                        >
                          <ReasoningTrigger />
                          <ReasoningContent>{part.text}</ReasoningContent>
                        </Reasoning>
                      );

                    default:
                      // Handle tool parts
                      if (part.type.startsWith('tool-')) {
                        return (
                          <Tool key={i}>
                            <ToolHeader
                              title={part.toolName}
                              type={part.type}
                              state={part.state}
                            />
                            <ToolContent>
                              <ToolInput input={part.input} />
                              <ToolOutput
                                output={part.output}
                                errorText={part.errorText}
                              />
                            </ToolContent>
                          </Tool>
                        );
                      }
                      return null;
                  }
                })}
              </div>
            ))}
            {status === 'submitted' && <Loader />}
          </ConversationContent>
          <ConversationScrollButton />
        </Conversation>

        <div className="border-t p-4">
          <PromptInput onSubmit={handleSubmit}>
            <PromptInputBody>
              <PromptInputTextarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Ask the agent anything..."
              />
            </PromptInputBody>
            <PromptInputFooter>
              <div />
              <PromptInputSubmit status={status} />
            </PromptInputFooter>
          </PromptInput>
        </div>
      </main>
    </div>
  );
}
```

---

## Multi-Agent Setup

### Multiple Agents

```typescript
// ai/research.ts
import { ToolLoopAgent, tool, stepCountIs } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { z } from 'zod';

export const researchAgent = new ToolLoopAgent({
  model: anthropic('claude-sonnet-4-5'),
  instructions: 'You are a research assistant. Find and summarize information.',
  tools: {
    searchWeb: tool({
      description: 'Search for information',
      inputSchema: z.object({ query: z.string() }),
      execute: async ({ query }) => ({ results: [`Found: ${query}`] }),
    }),
  },
  stopWhen: stepCountIs(10),
});
```

```typescript
// ai/code.ts
import { ToolLoopAgent, tool, stepCountIs } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { z } from 'zod';

export const codeAgent = new ToolLoopAgent({
  model: anthropic('claude-sonnet-4-5'),
  instructions: 'You are a coding assistant. Write and review code.',
  tools: {
    runCode: tool({
      description: 'Execute code',
      inputSchema: z.object({ code: z.string(), language: z.string() }),
      execute: async ({ code, language }) => ({
        output: `Executed ${language} code`,
      }),
    }),
  },
  stopWhen: stepCountIs(15),
});
```

```typescript
// ai/writing.ts
import { ToolLoopAgent, stepCountIs } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';

export const writingAgent = new ToolLoopAgent({
  model: anthropic('claude-sonnet-4-5'),
  instructions: 'You are a writing assistant. Help with content creation.',
  tools: {},
  stopWhen: stepCountIs(10),
});
```

### Agent Router API

```typescript
// app/api/chat/route.ts
import { createAgentUIStreamResponse } from 'ai';
import { researchAgent } from '@/ai/research';
import { codeAgent } from '@/ai/code';
import { writingAgent } from '@/ai/writing';

export const maxDuration = 30;

const agents = {
  research: researchAgent,
  code: codeAgent,
  writing: writingAgent,
};

export async function POST(request: Request) {
  const { messages, agentType = 'research' } = await request.json();

  const agent = agents[agentType as keyof typeof agents] || researchAgent;

  return createAgentUIStreamResponse({
    agent,
    uiMessages: messages,
    sendSources: true,
  });
}
```

### Agent Selector UI

```tsx
// Add to dashboard
const [agentType, setAgentType] = useState<'research' | 'code' | 'writing'>('research');

// In handleSubmit:
sendMessage(
  { text: message.text },
  { body: { agentType } }
);

// Agent selector component
<div className="flex gap-2 mb-4">
  {['research', 'code', 'writing'].map((type) => (
    <button
      key={type}
      onClick={() => setAgentType(type as any)}
      className={cn(
        'px-3 py-1 rounded-full text-sm',
        agentType === type ? 'bg-primary text-primary-foreground' : 'bg-muted'
      )}
    >
      {type.charAt(0).toUpperCase() + type.slice(1)}
    </button>
  ))}
</div>
```

---

## Tool Approval Flow (Human-in-the-Loop)

For sensitive tools that require user confirmation before execution.

In AI SDK, tools requiring approval **omit the `execute` function**. The agent loop pauses when such a tool is called, allowing the client to handle approval.

### Agent with Approval Tools

```typescript
// ai/admin-agent.ts
import { ToolLoopAgent, tool, stepCountIs } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { z } from 'zod';

export const adminAgent = new ToolLoopAgent({
  model: anthropic('claude-sonnet-4-5'),
  instructions: 'You are an admin assistant with access to sensitive operations.',
  tools: {
    // Tool requiring approval - NO execute function
    deleteFile: tool({
      description: 'Delete a file (requires approval)',
      inputSchema: z.object({
        path: z.string().describe('File path to delete'),
      }),
      outputSchema: z.string(),
      // NO execute - agent loop pauses, client handles approval
    }),
    // Tool with automatic execution
    readFile: tool({
      description: 'Read file contents',
      inputSchema: z.object({
        path: z.string().describe('File path to read'),
      }),
      execute: async ({ path }) => {
        return { content: `Contents of ${path}` };
      },
    }),
  },
  stopWhen: stepCountIs(20),
});
```

### Approval UI

```tsx
import { useChat } from '@ai-sdk/react';
import {
  Confirmation,
  ConfirmationTitle,
  ConfirmationRequest,
  ConfirmationAccepted,
  ConfirmationRejected,
  ConfirmationActions,
  ConfirmationAction,
} from '@/components/ai-elements/confirmation';

// In your component:
const { messages, sendMessage, addToolOutput } = useChat();

// In message parts rendering - check for 'input-available' state
if (part.type === 'tool-invocation' && part.state === 'input-available') {
  return (
    <Confirmation key={i} state={part.state}>
      <ConfirmationTitle>
        Tool <code>{part.toolName}</code> requires approval
      </ConfirmationTitle>
      <ConfirmationRequest>
        <p className="text-sm text-muted-foreground">
          Input: {JSON.stringify(part.input)}
        </p>
        <ConfirmationActions>
          <ConfirmationAction
            variant="outline"
            onClick={() => {
              addToolOutput({
                toolCallId: part.toolCallId,
                output: 'Denied by user',
              });
              sendMessage();
            }}
          >
            Deny
          </ConfirmationAction>
          <ConfirmationAction
            onClick={async () => {
              // Execute the actual operation after approval
              const result = await fetch('/api/delete-file', {
                method: 'POST',
                body: JSON.stringify({ path: part.input.path }),
              }).then((r) => r.json());

              addToolOutput({
                toolCallId: part.toolCallId,
                output: JSON.stringify(result),
              });
              sendMessage();
            }}
          >
            Allow
          </ConfirmationAction>
        </ConfirmationActions>
      </ConfirmationRequest>
      <ConfirmationAccepted>
        <p className="text-sm text-green-600">Approved</p>
      </ConfirmationAccepted>
      <ConfirmationRejected>
        <p className="text-sm text-red-600">Denied</p>
      </ConfirmationRejected>
    </Confirmation>
  );
}
```

See [Human-in-the-Loop Cookbook](https://ai-sdk.dev/cookbook/next/human-in-the-loop) for more details.

---

## Reference

For more details, see:
- `/ai-sdk-6` skill → [agents.md](../../ai-sdk-6/references/agents.md) - Full agent API
- `/ai-sdk-6` skill → [tools.md](../../ai-sdk-6/references/tools.md) - Tool definitions
- `/ai-elements` skill → [chatbot.md](../../ai-elements/references/chatbot.md) - Tool component
