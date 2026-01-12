# Chatbot Components

Detailed reference for AI Elements chatbot components.

## Conversation

Auto-scrolling chat container using `use-stick-to-bottom`.

```tsx
import {
  Conversation,
  ConversationContent,
  ConversationScrollButton,
  ConversationEmptyState,
} from '@/components/ai-elements/conversation';

<Conversation>
  <ConversationContent>
    {messages.length === 0 ? (
      <ConversationEmptyState
        title="Start a conversation"
        description="Ask me anything!"
        icon={<MessageIcon />}
      />
    ) : (
      messages.map((msg) => <Message key={msg.id} ... />)
    )}
  </ConversationContent>
  <ConversationScrollButton />
</Conversation>
```

### Props

| Component | Props |
|-----------|-------|
| `Conversation` | Extends `StickToBottom` - auto-scroll container |
| `ConversationContent` | Content wrapper with gap-8 padding |
| `ConversationScrollButton` | Shows when not at bottom, scrolls to bottom |
| `ConversationEmptyState` | `title?`, `description?`, `icon?` |

## Message

Single message with role-based styling.

```tsx
import {
  Message,
  MessageContent,
  MessageResponse,
  MessageActions,
  MessageAction,
  MessageAttachment,
  MessageAttachments,
} from '@/components/ai-elements/message';

<Message from="assistant">
  <MessageContent>
    <MessageResponse>{text}</MessageResponse>
  </MessageContent>
  <MessageActions>
    <MessageAction label="Copy" onClick={() => navigator.clipboard.writeText(text)}>
      <CopyIcon className="size-3" />
    </MessageAction>
    <MessageAction label="Retry" onClick={() => regenerate()}>
      <RefreshCcwIcon className="size-3" />
    </MessageAction>
  </MessageActions>
</Message>
```

### Props

| Component | Props |
|-----------|-------|
| `Message` | `from: "user" \| "assistant"` - determines styling |
| `MessageContent` | Styled wrapper (rounded bg for user) |
| `MessageResponse` | Streaming markdown via `Streamdown`, memoized |
| `MessageActions` | Action button container |
| `MessageAction` | `label?`, `tooltip?` - icon button |
| `MessageAttachment` | `data: FileUIPart`, `onRemove?` |
| `MessageAttachments` | Grid container for attachments |

### Message Branching

For multiple response variations (e.g., regenerated responses):

```tsx
import {
  MessageBranch,
  MessageBranchContent,
  MessageBranchSelector,
  MessageBranchPrevious,
  MessageBranchNext,
  MessageBranchPage,
} from '@/components/ai-elements/message';

<MessageBranch defaultBranch={0} onBranchChange={(i) => console.log(i)}>
  <MessageBranchContent>
    <Message from="assistant">Response 1</Message>
    <Message from="assistant">Response 2</Message>
    <Message from="assistant">Response 3</Message>
  </MessageBranchContent>
  <MessageBranchSelector from="assistant">
    <MessageBranchPrevious />
    <MessageBranchPage /> {/* Shows "1 of 3" */}
    <MessageBranchNext />
  </MessageBranchSelector>
</MessageBranch>
```

## PromptInput

Rich input with file attachments, model picker, and action menu.

### Basic Usage

```tsx
import {
  PromptInput,
  PromptInputBody,
  PromptInputTextarea,
  PromptInputFooter,
  PromptInputSubmit,
  type PromptInputMessage,
} from '@/components/ai-elements/prompt-input';

const handleSubmit = (message: PromptInputMessage) => {
  sendMessage({
    text: message.text,
    files: message.files,
  });
};

<PromptInput onSubmit={handleSubmit}>
  <PromptInputBody>
    <PromptInputTextarea value={input} onChange={(e) => setInput(e.target.value)} />
  </PromptInputBody>
  <PromptInputFooter>
    <PromptInputSubmit status={status} />
  </PromptInputFooter>
</PromptInput>
```

### Full Featured

```tsx
import {
  PromptInput,
  PromptInputHeader,
  PromptInputBody,
  PromptInputFooter,
  PromptInputTextarea,
  PromptInputTools,
  PromptInputButton,
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
  PromptInputSpeechButton,
} from '@/components/ai-elements/prompt-input';

<PromptInput
  onSubmit={handleSubmit}
  globalDrop        // Accept drops anywhere on document
  multiple          // Allow multiple files
  accept="image/*"  // Only images
  maxFiles={5}
  maxFileSize={10 * 1024 * 1024} // 10MB
  onError={(err) => console.error(err.code, err.message)}
>
  <PromptInputHeader>
    <PromptInputAttachments>
      {(attachment) => <PromptInputAttachment data={attachment} />}
    </PromptInputAttachments>
  </PromptInputHeader>

  <PromptInputBody>
    <PromptInputTextarea
      value={input}
      onChange={(e) => setInput(e.target.value)}
      placeholder="What would you like to know?"
    />
  </PromptInputBody>

  <PromptInputFooter>
    <PromptInputTools>
      {/* Action Menu */}
      <PromptInputActionMenu>
        <PromptInputActionMenuTrigger />
        <PromptInputActionMenuContent>
          <PromptInputActionAddAttachments label="Add photos or files" />
        </PromptInputActionMenuContent>
      </PromptInputActionMenu>

      {/* Custom Toggle Button */}
      <PromptInputButton
        variant={webSearch ? 'default' : 'ghost'}
        onClick={() => setWebSearch(!webSearch)}
      >
        <GlobeIcon size={16} />
        <span>Search</span>
      </PromptInputButton>

      {/* Model Selector */}
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

      {/* Speech Input */}
      <PromptInputSpeechButton textareaRef={textareaRef} />
    </PromptInputTools>

    <PromptInputSubmit status={status} />
  </PromptInputFooter>
</PromptInput>
```

### Props

| Prop | Type | Description |
|------|------|-------------|
| `onSubmit` | `(message: PromptInputMessage, event) => void` | Submit handler |
| `accept` | `string` | File type filter (e.g., `"image/*"`) |
| `multiple` | `boolean` | Allow multiple files |
| `globalDrop` | `boolean` | Accept drops anywhere on document |
| `maxFiles` | `number` | Maximum number of files |
| `maxFileSize` | `number` | Max file size in bytes |
| `onError` | `(err) => void` | Error callback (`max_files`, `max_file_size`, `accept`) |

### PromptInputMessage Type

```typescript
type PromptInputMessage = {
  text: string;
  files: FileUIPart[];
};
```

### Keyboard Shortcuts

- **Enter** - Submit (unless Shift held or composing)
- **Backspace** - Remove last attachment when textarea empty
- **Paste** - Paste images/files from clipboard

## Reasoning

Collapsible thinking/reasoning display with auto-collapse.

```tsx
import {
  Reasoning,
  ReasoningTrigger,
  ReasoningContent,
} from '@/components/ai-elements/reasoning';

<Reasoning
  isStreaming={status === 'streaming'}
  defaultOpen={true}
  duration={10} // seconds
>
  <ReasoningTrigger
    getThinkingMessage={(isStreaming, duration) =>
      isStreaming ? 'Thinking...' : `Thought for ${duration}s`
    }
  />
  <ReasoningContent>{reasoningText}</ReasoningContent>
</Reasoning>
```

### Props

| Prop | Type | Description |
|------|------|-------------|
| `isStreaming` | `boolean` | Track if reasoning is streaming |
| `open` | `boolean` | Controlled open state |
| `defaultOpen` | `boolean` | Initial state (default: `true`) |
| `onOpenChange` | `(open) => void` | Open state callback |
| `duration` | `number` | Time spent reasoning (seconds) |

### Behavior

- Opens automatically when `isStreaming=true`
- Auto-closes 1000ms after streaming ends (one-time only)
- Shows shimmer animation while streaming

## Sources

Collapsible citation/reference display.

```tsx
import {
  Sources,
  SourcesTrigger,
  SourcesContent,
  Source,
} from '@/components/ai-elements/sources';

const sourceUrls = message.parts.filter((p) => p.type === 'source-url');

{sourceUrls.length > 0 && (
  <Sources>
    <SourcesTrigger count={sourceUrls.length} />
    <SourcesContent>
      {sourceUrls.map((part, i) => (
        <Source key={i} href={part.url} title={part.title} />
      ))}
    </SourcesContent>
  </Sources>
)}
```

### Props

| Component | Props |
|-----------|-------|
| `SourcesTrigger` | `count: number` - number of sources |
| `Source` | `href: string`, `title?: string` |

## Tool

Tool execution visualization with status indicators.

```tsx
import {
  Tool,
  ToolHeader,
  ToolContent,
  ToolInput,
  ToolOutput,
} from '@/components/ai-elements/tool';

{part.type.startsWith('tool-') && (
  <Tool>
    <ToolHeader
      title={part.toolName}
      type={part.type}
      state={part.state}
    />
    <ToolContent>
      <ToolInput input={part.input} />
      <ToolOutput output={part.output} errorText={part.errorText} />
    </ToolContent>
  </Tool>
)}
```

### Tool States

| State | Icon | Color |
|-------|------|-------|
| `input-streaming` | Circle | Gray |
| `input-available` | Pulsing clock | Gray |
| `approval-requested` | Clock | Yellow |
| `approval-responded` | Check | Blue |
| `output-available` | Check | Green |
| `output-error` | X | Red |
| `output-denied` | X | Orange |

## ChainOfThought

Step-by-step reasoning breakdown.

```tsx
import {
  ChainOfThought,
  ChainOfThoughtHeader,
  ChainOfThoughtContent,
  ChainOfThoughtStep,
  ChainOfThoughtSearchResults,
  ChainOfThoughtImage,
} from '@/components/ai-elements/chain-of-thought';

<ChainOfThought defaultOpen={false}>
  <ChainOfThoughtHeader>View reasoning steps</ChainOfThoughtHeader>
  <ChainOfThoughtContent>
    <ChainOfThoughtStep
      icon={SearchIcon}
      label="Searching web"
      description="Found 5 results"
      status="complete"
    />
    <ChainOfThoughtStep
      icon={BrainIcon}
      label="Analyzing results"
      status="active"
    />
    <ChainOfThoughtStep
      icon={PenIcon}
      label="Writing response"
      status="pending"
    />
    <ChainOfThoughtSearchResults>
      <Badge>Result 1</Badge>
      <Badge>Result 2</Badge>
    </ChainOfThoughtSearchResults>
  </ChainOfThoughtContent>
</ChainOfThought>
```

### Step Status

- `complete` - Green check, completed step
- `active` - Pulsing indicator, current step
- `pending` - Gray, waiting step

## Loader

Loading indicator for submitted state.

```tsx
import { Loader } from '@/components/ai-elements/loader';

{status === 'submitted' && <Loader />}
```

## InlineCitation

Inline citation badge with hover card and carousel for multiple sources.

```tsx
import {
  InlineCitation,
  InlineCitationText,
  InlineCitationCard,
  InlineCitationCardTrigger,
  InlineCitationCardBody,
  InlineCitationCarousel,
  InlineCitationCarouselHeader,
  InlineCitationCarouselPrev,
  InlineCitationCarouselIndex,
  InlineCitationCarouselNext,
  InlineCitationCarouselContent,
  InlineCitationCarouselItem,
  InlineCitationSource,
  InlineCitationQuote,
} from '@/components/ai-elements/inline-citation';

<InlineCitation>
  <InlineCitationText>cited text here</InlineCitationText>
  <InlineCitationCard>
    <InlineCitationCardTrigger sources={['https://example.com']} />
    <InlineCitationCardBody>
      <InlineCitationCarousel>
        <InlineCitationCarouselHeader>
          <InlineCitationCarouselPrev />
          <InlineCitationCarouselIndex />
          <InlineCitationCarouselNext />
        </InlineCitationCarouselHeader>
        <InlineCitationCarouselContent>
          <InlineCitationCarouselItem>
            <InlineCitationSource
              title="Source Title"
              url="https://example.com"
              description="Source description..."
            />
            <InlineCitationQuote>Quoted text from source</InlineCitationQuote>
          </InlineCitationCarouselItem>
        </InlineCitationCarouselContent>
      </InlineCitationCarousel>
    </InlineCitationCardBody>
  </InlineCitationCard>
</InlineCitation>
```

### Props

| Component | Props |
|-----------|-------|
| `InlineCitationCardTrigger` | `sources: string[]` - array of URLs |
| `InlineCitationSource` | `title?`, `url?`, `description?` |

## Plan

Collapsible plan card with streaming shimmer effect on title/description.

```tsx
import {
  Plan,
  PlanHeader,
  PlanTitle,
  PlanDescription,
  PlanAction,
  PlanContent,
  PlanFooter,
  PlanTrigger,
} from '@/components/ai-elements/plan';

<Plan isStreaming={status === 'streaming'} defaultOpen>
  <PlanHeader>
    <div>
      <PlanTitle>Implementation Plan</PlanTitle>
      <PlanDescription>Steps to complete the task</PlanDescription>
    </div>
    <PlanAction>
      <PlanTrigger />
    </PlanAction>
  </PlanHeader>
  <PlanContent>
    <ul>
      <li>Step 1: Research</li>
      <li>Step 2: Design</li>
      <li>Step 3: Implement</li>
    </ul>
  </PlanContent>
  <PlanFooter>
    <Button>Execute Plan</Button>
  </PlanFooter>
</Plan>
```

### Props

| Prop | Type | Description |
|------|------|-------------|
| `isStreaming` | `boolean` | Shows shimmer effect on title/description |
| `defaultOpen` | `boolean` | Initial collapsed state |

## Task

Collapsible task breakdown display with file references.

```tsx
import {
  Task,
  TaskTrigger,
  TaskContent,
  TaskItem,
  TaskItemFile,
} from '@/components/ai-elements/task';

<Task defaultOpen>
  <TaskTrigger title="Searching codebase..." />
  <TaskContent>
    <TaskItem>
      Found in <TaskItemFile>src/components/Button.tsx</TaskItemFile>
    </TaskItem>
    <TaskItem>
      Also referenced in <TaskItemFile>src/pages/index.tsx</TaskItemFile>
    </TaskItem>
  </TaskContent>
</Task>
```

### Props

| Component | Props |
|-----------|-------|
| `Task` | `defaultOpen?: boolean` (default: `true`) |
| `TaskTrigger` | `title: string` |

## Queue

Todo/message queue display with sections for pending and completed items.

```tsx
import {
  Queue,
  QueueSection,
  QueueSectionTrigger,
  QueueSectionLabel,
  QueueSectionContent,
  QueueList,
  QueueItem,
  QueueItemIndicator,
  QueueItemContent,
  QueueItemDescription,
  QueueItemActions,
  QueueItemAction,
  QueueItemAttachment,
  QueueItemImage,
  QueueItemFile,
} from '@/components/ai-elements/queue';

<Queue>
  <QueueSection>
    <QueueSectionTrigger>
      <QueueSectionLabel
        count={3}
        label="pending"
        icon={<ClockIcon className="size-4" />}
      />
    </QueueSectionTrigger>
    <QueueSectionContent>
      <QueueList>
        <QueueItem>
          <div className="flex items-center gap-2">
            <QueueItemIndicator />
            <QueueItemContent>Task description here</QueueItemContent>
          </div>
          <QueueItemDescription>Additional details</QueueItemDescription>
          <QueueItemAttachment>
            <QueueItemImage src="/image.png" />
            <QueueItemFile>document.pdf</QueueItemFile>
          </QueueItemAttachment>
          <QueueItemActions>
            <QueueItemAction onClick={() => {}}>
              <TrashIcon className="size-3" />
            </QueueItemAction>
          </QueueItemActions>
        </QueueItem>
      </QueueList>
    </QueueSectionContent>
  </QueueSection>
</Queue>
```

### Props

| Component | Props |
|-----------|-------|
| `QueueSection` | `defaultOpen?: boolean` (default: `true`) |
| `QueueSectionLabel` | `count?: number`, `label: string`, `icon?: ReactNode` |
| `QueueItemIndicator` | `completed?: boolean` |
| `QueueItemContent` | `completed?: boolean` |

## Complete Chatbot Example

See [SKILL.md](../SKILL.md) for core integration pattern, or the full tutorial in the AI Elements documentation.
