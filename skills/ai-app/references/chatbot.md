# Chatbot Templates

Complete templates for building AI chatbots.

## Minimal Chatbot

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
    system: 'You are a helpful assistant.',
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
import { Loader } from '@/components/ai-elements/loader';
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
    <div className="mx-auto flex h-screen max-w-3xl flex-col p-4">
      <Conversation className="flex-1">
        <ConversationContent>
          {messages.map((message) => (
            <div key={message.id}>
              {message.parts.map((part, i) =>
                part.type === 'text' ? (
                  <Message key={i} from={message.role}>
                    <MessageContent>
                      <MessageResponse>{part.text}</MessageResponse>
                    </MessageContent>
                  </Message>
                ) : null
              )}
            </div>
          ))}
          {status === 'submitted' && <Loader />}
        </ConversationContent>
      </Conversation>

      <PromptInput onSubmit={handleSubmit} className="mt-4">
        <PromptInputBody>
          <PromptInputTextarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
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

With reasoning, sources, file attachments, model selector, and message actions.

### API Route

```typescript
// app/api/chat/route.ts
import { streamText, UIMessage, convertToModelMessages } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';

export const maxDuration = 30;

export async function POST(req: Request) {
  const {
    messages,
    model = 'claude-sonnet-4-5',
  }: {
    messages: UIMessage[];
    model?: string;
  } = await req.json();

  const result = streamText({
    model: anthropic(model),
    messages: convertToModelMessages(messages),
    system: 'You are a helpful assistant. Think step by step.',
  });

  return result.toUIMessageStreamResponse({
    sendSources: true,
    sendReasoning: true,
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
  MessageActions,
  MessageAction,
} from '@/components/ai-elements/message';
import {
  PromptInput,
  PromptInputHeader,
  PromptInputBody,
  PromptInputTextarea,
  PromptInputFooter,
  PromptInputTools,
  PromptInputSubmit,
  PromptInputAttachments,
  PromptInputAttachment,
  PromptInputActionMenu,
  PromptInputActionMenuTrigger,
  PromptInputActionMenuContent,
  PromptInputActionAddAttachments,
  PromptInputSelect,
  PromptInputSelectTrigger,
  PromptInputSelectValue,
  PromptInputSelectContent,
  PromptInputSelectItem,
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
import { CopyIcon, RefreshCcwIcon } from 'lucide-react';
import { useState } from 'react';

const models = [
  { name: 'Claude Sonnet', value: 'claude-sonnet-4-5' },
  { name: 'Claude Haiku', value: 'claude-haiku-4-5' },
];

export default function ChatPage() {
  const [input, setInput] = useState('');
  const [model, setModel] = useState(models[0].value);
  const { messages, sendMessage, status, regenerate } = useChat();

  const handleSubmit = (message: PromptInputMessage) => {
    if (!message.text.trim() && !message.files?.length) return;
    sendMessage(
      { text: message.text || 'Sent with attachments', files: message.files },
      { body: { model } }
    );
    setInput('');
  };

  return (
    <div className="mx-auto flex h-screen max-w-4xl flex-col p-6">
      <Conversation className="flex-1">
        <ConversationContent>
          {messages.map((message) => {
            const sourceUrls = message.parts.filter((p) => p.type === 'source-url');

            return (
              <div key={message.id}>
                {/* Sources at top */}
                {message.role === 'assistant' && sourceUrls.length > 0 && (
                  <Sources>
                    <SourcesTrigger count={sourceUrls.length} />
                    <SourcesContent>
                      {sourceUrls.map((part, i) => (
                        <Source key={i} href={part.url} title={part.title} />
                      ))}
                    </SourcesContent>
                  </Sources>
                )}

                {/* Message parts */}
                {message.parts.map((part, i) => {
                  switch (part.type) {
                    case 'text':
                      return (
                        <Message key={i} from={message.role}>
                          <MessageContent>
                            <MessageResponse>{part.text}</MessageResponse>
                          </MessageContent>
                          {message.role === 'assistant' && (
                            <MessageActions>
                              <MessageAction
                                label="Retry"
                                onClick={() => regenerate()}
                              >
                                <RefreshCcwIcon className="size-3" />
                              </MessageAction>
                              <MessageAction
                                label="Copy"
                                onClick={() => navigator.clipboard.writeText(part.text)}
                              >
                                <CopyIcon className="size-3" />
                              </MessageAction>
                            </MessageActions>
                          )}
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
                      return null;
                  }
                })}
              </div>
            );
          })}
          {status === 'submitted' && <Loader />}
        </ConversationContent>
        <ConversationScrollButton />
      </Conversation>

      <PromptInput onSubmit={handleSubmit} className="mt-4" globalDrop multiple>
        <PromptInputHeader>
          <PromptInputAttachments>
            {(attachment) => <PromptInputAttachment data={attachment} />}
          </PromptInputAttachments>
        </PromptInputHeader>
        <PromptInputBody>
          <PromptInputTextarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
          />
        </PromptInputBody>
        <PromptInputFooter>
          <PromptInputTools>
            <PromptInputActionMenu>
              <PromptInputActionMenuTrigger />
              <PromptInputActionMenuContent>
                <PromptInputActionAddAttachments />
              </PromptInputActionMenuContent>
            </PromptInputActionMenu>
            <PromptInputSelect value={model} onValueChange={setModel}>
              <PromptInputSelectTrigger>
                <PromptInputSelectValue />
              </PromptInputSelectTrigger>
              <PromptInputSelectContent>
                {models.map((m) => (
                  <PromptInputSelectItem key={m.value} value={m.value}>
                    {m.name}
                  </PromptInputSelectItem>
                ))}
              </PromptInputSelectContent>
            </PromptInputSelect>
          </PromptInputTools>
          <PromptInputSubmit status={status} />
        </PromptInputFooter>
      </PromptInput>
    </div>
  );
}
```

---

## Web Search Chatbot

With Perplexity integration for web search. Perplexity has built-in web search and returns sources automatically.

### API Route

```typescript
// app/api/chat/route.ts
import { streamText, UIMessage, convertToModelMessages } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { perplexity } from '@ai-sdk/perplexity';

export const maxDuration = 30;

export async function POST(req: Request) {
  const {
    messages,
    webSearch = false,
  }: {
    messages: UIMessage[];
    webSearch?: boolean;
  } = await req.json();

  const result = streamText({
    // Use Perplexity for web search, Claude otherwise
    model: webSearch ? perplexity('sonar-pro') : anthropic('claude-sonnet-4-5'),
    messages: convertToModelMessages(messages),
    system: webSearch
      ? 'Search the web and provide accurate, up-to-date information with sources.'
      : 'You are a helpful assistant.',
  });

  return result.toUIMessageStreamResponse({
    sendSources: true,
    sendReasoning: true,
  });
}
```

Available Perplexity models: `sonar`, `sonar-pro`, `sonar-reasoning`, `sonar-reasoning-pro`, `sonar-deep-research`

### Chat Page Addition

Add web search toggle to PromptInput:

```tsx
import { GlobeIcon } from 'lucide-react';
import { PromptInputButton } from '@/components/ai-elements/prompt-input';

// In component:
const [webSearch, setWebSearch] = useState(false);

// In handleSubmit:
sendMessage(
  { text: message.text },
  { body: { webSearch } }
);

// In PromptInputTools:
<PromptInputButton
  variant={webSearch ? 'default' : 'ghost'}
  onClick={() => setWebSearch(!webSearch)}
>
  <GlobeIcon size={16} />
  <span>Search</span>
</PromptInputButton>
```

---

## Component Reference

For detailed component documentation, see `/ai-elements` skill:
- [Conversation](../../ai-elements/references/chatbot.md#conversation)
- [Message](../../ai-elements/references/chatbot.md#message)
- [PromptInput](../../ai-elements/references/chatbot.md#promptinput)
- [Reasoning](../../ai-elements/references/chatbot.md#reasoning)
- [Sources](../../ai-elements/references/chatbot.md#sources)
