# Copy-Paste Examples

Ready-to-use examples for common AI application patterns.

---

## Minimal Chatbot

The simplest possible chatbot implementation.

### API Route

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
  });

  return result.toUIMessageStreamResponse();
}
```

### Chat Page

```tsx
// app/page.tsx
'use client';
import { useChat } from '@ai-sdk/react';
import {
  Conversation,
  ConversationContent,
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
import { useState } from 'react';

export default function ChatPage() {
  const [input, setInput] = useState('');
  const { messages, sendMessage, status } = useChat();

  const handleSubmit = (message: PromptInputMessage) => {
    if (!message.text.trim()) return;
    sendMessage({ text: message.text });
    setInput('');
  };

  return (
    <div className="mx-auto flex h-screen max-w-2xl flex-col p-4">
      <Conversation className="flex-1">
        <ConversationContent>
          {messages.map((message) => (
            <Message key={message.id} from={message.role}>
              <MessageContent>
                {message.parts
                  .filter((p) => p.type === 'text')
                  .map((part, i) => (
                    <MessageResponse key={i}>{part.text}</MessageResponse>
                  ))}
              </MessageContent>
            </Message>
          ))}
        </ConversationContent>
      </Conversation>

      <PromptInput onSubmit={handleSubmit} className="mt-4">
        <PromptInputBody>
          <PromptInputTextarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Type a message..."
          />
        </PromptInputBody>
        <PromptInputFooter>
          <div />
          <PromptInputSubmit status={status} />
        </PromptInputFooter>
      </PromptInput>
    </div>
  );
}
```

---

## Full-Featured Chatbot

Chatbot with reasoning, sources, and file attachments.

### API Route

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
    system: `You are a helpful AI assistant. When appropriate:
- Use extended thinking to reason through complex problems
- Cite sources when providing factual information
- Be concise but thorough`,
    providerOptions: {
      anthropic: {
        thinking: {
          type: 'enabled',
          budgetTokens: 10000,
        },
      },
    },
  });

  return result.toUIMessageStreamResponse({
    sendReasoning: true,
    sendSources: true,
  });
}
```

### Chat Page

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
  MessageAttachment,
} from '@/components/ai-elements/message';
import {
  PromptInput,
  PromptInputBody,
  PromptInputTextarea,
  PromptInputFooter,
  PromptInputSubmit,
  PromptInputFileDropdown,
  PromptInputAttachments,
  type PromptInputMessage,
} from '@/components/ai-elements/prompt-input';
import {
  Reasoning,
  ReasoningTrigger,
  ReasoningContent,
} from '@/components/ai-elements/reasoning';
import {
  Sources,
  SourcesTrigger,
  SourcesContent,
  Source,
} from '@/components/ai-elements/sources';
import { Loader } from '@/components/ai-elements/loader';
import { useState } from 'react';

export default function ChatPage() {
  const [input, setInput] = useState('');
  const [files, setFiles] = useState<File[]>([]);
  const { messages, sendMessage, status } = useChat();

  const handleSubmit = (message: PromptInputMessage) => {
    if (!message.text.trim() && message.files.length === 0) return;
    sendMessage({ text: message.text, files: message.files });
    setInput('');
    setFiles([]);
  };

  const isLastMessage = (id: string) => id === messages.at(-1)?.id;

  return (
    <div className="mx-auto flex h-screen max-w-3xl flex-col p-4">
      <Conversation className="flex-1">
        <ConversationContent>
          {messages.map((message) => (
            <div key={message.id} className="space-y-2">
              {/* User attachments */}
              {message.role === 'user' && message.attachments?.length > 0 && (
                <div className="flex flex-wrap gap-2">
                  {message.attachments.map((att, i) => (
                    <MessageAttachment key={i} attachment={att} />
                  ))}
                </div>
              )}

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
                          status === 'streaming' && isLastMessage(message.id)
                        }
                      >
                        <ReasoningTrigger />
                        <ReasoningContent>{part.text}</ReasoningContent>
                      </Reasoning>
                    );

                  case 'source-url':
                    return null; // Collected below

                  default:
                    return null;
                }
              })}

              {/* Collect and display sources */}
              {message.parts.some((p) => p.type === 'source-url') && (
                <Sources>
                  <SourcesTrigger />
                  <SourcesContent>
                    {message.parts
                      .filter((p) => p.type === 'source-url')
                      .map((part, i) => (
                        <Source
                          key={i}
                          href={part.url}
                          title={part.title}
                          favicon={part.providerMetadata?.favicon}
                        />
                      ))}
                  </SourcesContent>
                </Sources>
              )}
            </div>
          ))}
          {status === 'submitted' && <Loader />}
        </ConversationContent>
        <ConversationScrollButton />
      </Conversation>

      <PromptInput onSubmit={handleSubmit} className="mt-4">
        <PromptInputAttachments files={files} setFiles={setFiles} />
        <PromptInputBody>
          <PromptInputFileDropdown files={files} setFiles={setFiles} />
          <PromptInputTextarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Ask me anything..."
          />
        </PromptInputBody>
        <PromptInputFooter>
          <div />
          <PromptInputSubmit status={status} />
        </PromptInputFooter>
      </PromptInput>
    </div>
  );
}
```

---

## Agent with Tools

An agent that can search the web and perform calculations.

### Agent Definition

```typescript
// ai/assistant.ts
import { ToolLoopAgent, tool, stepCountIs } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { z } from 'zod';

export const assistantAgent = new ToolLoopAgent({
  model: anthropic('claude-sonnet-4-5'),
  instructions: `You are a helpful assistant with access to tools.
When you need current information, use the searchWeb tool.
When calculating, use the calculator tool.
Always explain what you're doing before using a tool.`,
  tools: {
    searchWeb: tool({
      description: 'Search the web for current information',
      inputSchema: z.object({
        query: z.string().describe('The search query'),
      }),
      execute: async ({ query }) => {
        // Replace with actual search implementation
        // e.g., Tavily, Serper, or Perplexity API
        return {
          results: [
            { title: 'Result 1', snippet: `Information about ${query}` },
            { title: 'Result 2', snippet: `More about ${query}` },
          ],
        };
      },
    }),
    calculator: tool({
      description: 'Perform mathematical calculations',
      inputSchema: z.object({
        expression: z.string().describe('Math expression (e.g., "2 + 2")'),
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
    getCurrentDate: tool({
      description: 'Get the current date and time',
      inputSchema: z.object({}),
      execute: async () => ({
        date: new Date().toLocaleDateString(),
        time: new Date().toLocaleTimeString(),
      }),
    }),
  },
  stopWhen: stepCountIs(15),
});
```

### API Route

```typescript
// app/api/chat/route.ts
import { createAgentUIStreamResponse } from 'ai';
import { assistantAgent } from '@/ai/assistant';

export const maxDuration = 60;

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

### Agent Chat Page

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
import { Loader } from '@/components/ai-elements/loader';
import { useState } from 'react';

export default function AgentPage() {
  const [input, setInput] = useState('');
  const { messages, sendMessage, status } = useChat();

  const handleSubmit = (message: PromptInputMessage) => {
    if (!message.text.trim()) return;
    sendMessage({ text: message.text });
    setInput('');
  };

  return (
    <div className="mx-auto flex h-screen max-w-3xl flex-col p-4">
      <Conversation className="flex-1">
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

                  case 'tool-invocation':
                  case 'tool-result':
                    return (
                      <Tool key={i}>
                        <ToolHeader
                          title={part.toolName}
                          type={part.type}
                          state={part.state}
                        />
                        <ToolContent>
                          <ToolInput input={part.input} />
                          {part.state === 'output-available' && (
                            <ToolOutput output={part.output} />
                          )}
                        </ToolContent>
                      </Tool>
                    );

                  default:
                    return null;
                }
              })}
            </div>
          ))}
          {status === 'submitted' && <Loader />}
        </ConversationContent>
        <ConversationScrollButton />
      </Conversation>

      <PromptInput onSubmit={handleSubmit} className="mt-4">
        <PromptInputBody>
          <PromptInputTextarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Ask me to search or calculate..."
          />
        </PromptInputBody>
        <PromptInputFooter>
          <div />
          <PromptInputSubmit status={status} />
        </PromptInputFooter>
      </PromptInput>
    </div>
  );
}
```

---

## Multi-Agent System

Switch between specialized agents.

### Agent Definitions

```typescript
// ai/research.ts
import { ToolLoopAgent, tool, stepCountIs } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { z } from 'zod';

export const researchAgent = new ToolLoopAgent({
  model: anthropic('claude-sonnet-4-5'),
  instructions: 'You are a research assistant. Find and summarize information.',
  tools: {
    search: tool({
      description: 'Search for information',
      inputSchema: z.object({ query: z.string() }),
      execute: async ({ query }) => ({
        results: [`Research results for: ${query}`],
      }),
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
  instructions: 'You are a coding assistant. Write and explain code.',
  tools: {
    runCode: tool({
      description: 'Execute code snippet',
      inputSchema: z.object({
        code: z.string(),
        language: z.enum(['javascript', 'python']),
      }),
      execute: async ({ code, language }) => ({
        output: `Executed ${language}: ${code.slice(0, 50)}...`,
      }),
    }),
  },
  stopWhen: stepCountIs(10),
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

export type AgentType = 'research' | 'code' | 'writing';
```

### API Route with Agent Selection

```typescript
// app/api/chat/route.ts
import { createAgentUIStreamResponse } from 'ai';
import { researchAgent } from '@/ai/research';
import { codeAgent } from '@/ai/code';
import { writingAgent } from '@/ai/writing';
import type { AgentType } from '@/ai/writing';

export const maxDuration = 60;

const agents = {
  research: researchAgent,
  code: codeAgent,
  writing: writingAgent,
};

export async function POST(request: Request) {
  const { messages, agentType = 'research' } = await request.json();

  const agent = agents[agentType as AgentType] || agents.research;

  return createAgentUIStreamResponse({
    agent,
    uiMessages: messages,
    sendSources: true,
  });
}
```

### Agent Selector UI

```tsx
// components/agent-selector.tsx
'use client';
import { cn } from '@/lib/utils';
import type { AgentType } from '@/ai/writing';

const agentInfo = {
  research: { label: 'Research', icon: '🔍' },
  code: { label: 'Code', icon: '💻' },
  writing: { label: 'Writing', icon: '✍️' },
};

type AgentSelectorProps = {
  value: AgentType;
  onChange: (agent: AgentType) => void;
};

export function AgentSelector({ value, onChange }: AgentSelectorProps) {
  return (
    <div className="flex gap-2">
      {(Object.keys(agentInfo) as AgentType[]).map((type) => (
        <button
          key={type}
          onClick={() => onChange(type)}
          className={cn(
            'rounded-full px-3 py-1 text-sm transition-colors',
            value === type
              ? 'bg-primary text-primary-foreground'
              : 'bg-muted hover:bg-muted/80'
          )}
        >
          {agentInfo[type].icon} {agentInfo[type].label}
        </button>
      ))}
    </div>
  );
}
```

### Multi-Agent Page

```tsx
// app/page.tsx
'use client';
import { useChat } from '@ai-sdk/react';
import { useState } from 'react';
import type { AgentType } from '@/ai/writing';
import { AgentSelector } from '@/components/agent-selector';
// ... other imports

export default function MultiAgentPage() {
  const [input, setInput] = useState('');
  const [agentType, setAgentType] = useState<AgentType>('research');
  const { messages, sendMessage, status } = useChat();

  const handleSubmit = (message: PromptInputMessage) => {
    if (!message.text.trim()) return;
    sendMessage(
      { text: message.text },
      { body: { agentType } }
    );
    setInput('');
  };

  return (
    <div className="mx-auto flex h-screen max-w-3xl flex-col p-4">
      <div className="mb-4">
        <AgentSelector value={agentType} onChange={setAgentType} />
      </div>

      {/* Rest of chat UI same as Agent with Tools example */}
    </div>
  );
}
```

---

## Environment Variables

```bash
# .env.local - Choose your provider(s)

# Anthropic (Claude)
ANTHROPIC_API_KEY=sk-ant-...

# OpenAI (GPT-4, etc.)
OPENAI_API_KEY=sk-...

# Google Generative AI (Gemini)
GOOGLE_GENERATIVE_AI_API_KEY=...

# Perplexity (web search)
PERPLEXITY_API_KEY=pplx-...
```

---

## Quick Reference

| Example | Files | Key Features |
|---------|-------|--------------|
| Minimal Chatbot | route.ts, page.tsx | Basic chat, streamText |
| Full-Featured | route.ts, page.tsx | Reasoning, sources, attachments |
| Agent with Tools | ai/assistant.ts, route.ts, page.tsx | ToolLoopAgent, tool visualization |
| Multi-Agent | ai/*.ts, route.ts, page.tsx | Agent switching, specialized agents |

## See Also

- [Chatbot Templates](chatbot.md) - More chatbot patterns
- [Agent Dashboard](agent-dashboard.md) - Dashboard layouts
- [Project Structure](project-structure.md) - Full project setup
