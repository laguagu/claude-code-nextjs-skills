# Utility Components

Supporting components for AI applications.

## CodeBlock

Syntax highlighted code with copy button.

```tsx
import { CodeBlock, CodeBlockCopyButton } from '@/components/ai-elements/code-block';

<CodeBlock
  code={`const greeting = "Hello, World!";
console.log(greeting);`}
  language="typescript"
  showLineNumbers
>
  <CodeBlockCopyButton />
</CodeBlock>
```

### Props

| Prop | Type | Description |
|------|------|-------------|
| `code` | `string` | Code to display |
| `language` | `BundledLanguage` | Shiki language (e.g., `typescript`, `python`) |
| `showLineNumbers` | `boolean` | Show line numbers |

### Copy Button Props

| Prop | Type | Description |
|------|------|-------------|
| `onCopy` | `() => void` | Callback after successful copy |
| `onError` | `(error: Error) => void` | Error callback |
| `timeout` | `number` | Reset delay in ms (default: 2000) |

### Features

- Shiki syntax highlighting
- Light/dark theme support (one-light/one-dark-pro)
- Line numbers
- Copy to clipboard button
- Displays check icon after copying

## Loader

Spinning loading indicator.

```tsx
import { Loader } from '@/components/ai-elements/loader';

// Basic usage
<Loader />

// Custom size
<Loader size={24} />

// With custom styles
<Loader className="text-primary" />

// Common pattern with status
{status === 'submitted' && <Loader />}
```

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `size` | `number` | 16 | Icon size in pixels |
| `className` | `string` | - | Additional classes |

## Shimmer

Animated text shimmer effect for loading states.

```tsx
import { Shimmer } from '@/components/ai-elements/shimmer';

// Basic usage
<Shimmer>Thinking...</Shimmer>

// Custom element
<Shimmer as="span" duration={1.5}>Loading response</Shimmer>

// Custom spread
<Shimmer spread={3}>Processing your request</Shimmer>
```

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `children` | `string` | - | Text to animate |
| `as` | `ElementType` | `"p"` | HTML element to render |
| `duration` | `number` | 2 | Animation duration in seconds |
| `spread` | `number` | 2 | Shimmer spread multiplier |

### Dependencies

- `motion/react` (Framer Motion)

## Suggestions

Quick action chips for suggested prompts.

```tsx
import { Suggestions, Suggestion } from '@/components/ai-elements/suggestion';

const suggestions = [
  'What are the latest trends in AI?',
  'How does machine learning work?',
  'Explain quantum computing',
];

<Suggestions>
  {suggestions.map((suggestion) => (
    <Suggestion
      key={suggestion}
      suggestion={suggestion}
      onClick={(text) => {
        setInput(text);
        // or sendMessage({ text });
      }}
    />
  ))}
</Suggestions>
```

### Props

**Suggestions** - Horizontal scroll container

| Prop | Type | Description |
|------|------|-------------|
| `className` | `string` | Additional classes |
| `children` | `ReactNode` | Suggestion buttons |

**Suggestion** - Individual suggestion button

| Prop | Type | Description |
|------|------|-------------|
| `suggestion` | `string` | Suggestion text |
| `onClick` | `(suggestion: string) => void` | Click handler |
| `variant` | `string` | Button variant (default: `"outline"`) |
| `size` | `string` | Button size (default: `"sm"`) |

## Confirmation

Tool confirmation dialog for user approval.

```tsx
import {
  Confirmation,
  ConfirmationTitle,
  ConfirmationRequest,
  ConfirmationAccepted,
  ConfirmationRejected,
  ConfirmationActions,
  ConfirmationAction,
} from '@/components/ai-elements/confirmation';

<Confirmation
  approval={{ id: 'tool-1', approved: undefined }}
  state="approval-requested"
>
  <ConfirmationTitle>
    The AI wants to run <code>deleteFile()</code>
  </ConfirmationTitle>

  <ConfirmationRequest>
    <p className="text-sm text-muted-foreground">
      This will permanently delete the file. Continue?
    </p>
    <ConfirmationActions>
      <ConfirmationAction
        variant="outline"
        onClick={() => handleResponse(false, 'User declined')}
      >
        Deny
      </ConfirmationAction>
      <ConfirmationAction
        onClick={() => handleResponse(true)}
      >
        Allow
      </ConfirmationAction>
    </ConfirmationActions>
  </ConfirmationRequest>

  <ConfirmationAccepted>
    <p className="text-sm text-green-600">Action approved</p>
  </ConfirmationAccepted>

  <ConfirmationRejected>
    <p className="text-sm text-red-600">Action denied</p>
  </ConfirmationRejected>
</Confirmation>
```

### Props

| Prop | Type | Description |
|------|------|-------------|
| `approval` | `{ id, approved?, reason? }` | Approval state |
| `state` | `ToolUIPart["state"]` | Tool execution state |

### Conditional Components

- `ConfirmationRequest` - Shows when `state === "approval-requested"`
- `ConfirmationAccepted` - Shows when `approved === true`
- `ConfirmationRejected` - Shows when `approved === false`
- `ConfirmationActions` - Shows when `state === "approval-requested"`

## Artifact

Container for AI-generated content (code, documents, etc.).

```tsx
import {
  Artifact,
  ArtifactHeader,
  ArtifactTitle,
  ArtifactDescription,
  ArtifactActions,
  ArtifactAction,
  ArtifactClose,
  ArtifactContent,
} from '@/components/ai-elements/artifact';

<Artifact>
  <ArtifactHeader>
    <div className="flex flex-col">
      <ArtifactTitle>Generated Component</ArtifactTitle>
      <ArtifactDescription>React TypeScript component</ArtifactDescription>
    </div>
    <ArtifactActions>
      <ArtifactAction
        tooltip="Copy code"
        icon={CopyIcon}
        onClick={() => navigator.clipboard.writeText(code)}
      />
      <ArtifactAction
        tooltip="Download"
        icon={DownloadIcon}
        onClick={handleDownload}
      />
      <ArtifactClose onClick={onClose} />
    </ArtifactActions>
  </ArtifactHeader>
  <ArtifactContent>
    <CodeBlock code={code} language="tsx" />
  </ArtifactContent>
</Artifact>
```

### Components

| Component | Props |
|-----------|-------|
| `Artifact` | Container with rounded border |
| `ArtifactHeader` | Header with border-bottom |
| `ArtifactTitle` | Title text |
| `ArtifactDescription` | Muted description |
| `ArtifactActions` | Action buttons container |
| `ArtifactAction` | `tooltip?`, `label?`, `icon?` |
| `ArtifactClose` | X button with sr-only label |
| `ArtifactContent` | Scrollable content area |

## Image

AI-generated image display.

```tsx
import { Image } from '@/components/ai-elements/image';

<Image
  src={generatedImageUrl}
  alt="AI generated artwork"
  width={512}
  height={512}
/>
```

## ModelSelector

Model picker dialog with searchable list and provider logos.

```tsx
import {
  ModelSelector,
  ModelSelectorTrigger,
  ModelSelectorContent,
  ModelSelectorInput,
  ModelSelectorList,
  ModelSelectorEmpty,
  ModelSelectorGroup,
  ModelSelectorItem,
  ModelSelectorLogo,
  ModelSelectorLogoGroup,
  ModelSelectorName,
  ModelSelectorShortcut,
  ModelSelectorSeparator,
} from '@/components/ai-elements/model-selector';

<ModelSelector open={open} onOpenChange={setOpen}>
  <ModelSelectorTrigger asChild>
    <Button variant="outline">Select Model</Button>
  </ModelSelectorTrigger>
  <ModelSelectorContent>
    <ModelSelectorInput placeholder="Search models..." />
    <ModelSelectorList>
      <ModelSelectorEmpty>No models found.</ModelSelectorEmpty>
      <ModelSelectorGroup heading="Anthropic">
        <ModelSelectorItem onSelect={() => setModel('claude-3-5-sonnet')}>
          <ModelSelectorLogo provider="anthropic" />
          <ModelSelectorName>Claude 3.5 Sonnet</ModelSelectorName>
          <ModelSelectorShortcut>⌘1</ModelSelectorShortcut>
        </ModelSelectorItem>
      </ModelSelectorGroup>
      <ModelSelectorSeparator />
      <ModelSelectorGroup heading="OpenAI">
        <ModelSelectorItem onSelect={() => setModel('gpt-4o')}>
          <ModelSelectorLogoGroup>
            <ModelSelectorLogo provider="openai" />
            <ModelSelectorLogo provider="azure" />
          </ModelSelectorLogoGroup>
          <ModelSelectorName>GPT-4o</ModelSelectorName>
        </ModelSelectorItem>
      </ModelSelectorGroup>
    </ModelSelectorList>
  </ModelSelectorContent>
</ModelSelector>
```

### ModelSelectorLogo Providers

Supports many providers: `anthropic`, `openai`, `google`, `mistral`, `groq`, `perplexity`, `deepseek`, `azure`, `amazon-bedrock`, `google-vertex`, `fireworks-ai`, `togetherai`, `huggingface`, and more.

Logos are fetched from `https://models.dev/logos/{provider}.svg`.

## OpenIn

Dropdown menu to open a query in external chat providers.

```tsx
import {
  OpenIn,
  OpenInTrigger,
  OpenInContent,
  OpenInLabel,
  OpenInSeparator,
  OpenInChatGPT,
  OpenInClaude,
  OpenInScira,
  OpenInT3,
  OpenInv0,
  OpenInCursor,
} from '@/components/ai-elements/open-in-chat';

<OpenIn query="How do I implement authentication?">
  <OpenInTrigger />
  <OpenInContent>
    <OpenInLabel>Open in...</OpenInLabel>
    <OpenInSeparator />
    <OpenInChatGPT />
    <OpenInClaude />
    <OpenInScira />
    <OpenInT3 />
    <OpenInv0 />
    <OpenInCursor />
  </OpenInContent>
</OpenIn>
```

### Supported Providers

| Component | Opens URL |
|-----------|-----------|
| `OpenInChatGPT` | chatgpt.com |
| `OpenInClaude` | claude.ai/new |
| `OpenInScira` | scira.ai |
| `OpenInT3` | t3.chat/new |
| `OpenInv0` | v0.app |
| `OpenInCursor` | cursor.com/link/prompt |

## WebPreview

Iframe preview with URL navigation bar and console output.

```tsx
import {
  WebPreview,
  WebPreviewNavigation,
  WebPreviewNavigationButton,
  WebPreviewUrl,
  WebPreviewBody,
  WebPreviewConsole,
} from '@/components/ai-elements/web-preview';

const [logs, setLogs] = useState([]);

<WebPreview defaultUrl="http://localhost:3000" onUrlChange={(url) => console.log(url)}>
  <WebPreviewNavigation>
    <WebPreviewNavigationButton tooltip="Back" onClick={() => {}}>
      <ArrowLeftIcon className="size-4" />
    </WebPreviewNavigationButton>
    <WebPreviewNavigationButton tooltip="Refresh" onClick={() => {}}>
      <RefreshCwIcon className="size-4" />
    </WebPreviewNavigationButton>
    <WebPreviewUrl />
  </WebPreviewNavigation>
  <WebPreviewBody />
  <WebPreviewConsole logs={logs} />
</WebPreview>
```

### Props

| Component | Props |
|-----------|-------|
| `WebPreview` | `defaultUrl?`, `onUrlChange?` |
| `WebPreviewNavigationButton` | `tooltip?` |
| `WebPreviewBody` | `loading?: ReactNode` - loading overlay |
| `WebPreviewConsole` | `logs: Array<{ level, message, timestamp }>` |

### Console Log Levels

- `log` - Normal text color
- `warn` - Yellow text
- `error` - Red/destructive text

## Dependencies Summary

| Component | Dependencies |
|-----------|-------------|
| `CodeBlock` | `shiki` |
| `Shimmer` | `motion/react` |
| `Suggestions` | `@/components/ui/scroll-area` |
| `Confirmation` | `@/components/ui/alert`, `ai` types |
| `Artifact` | `@/components/ui/tooltip`, `lucide-react` |
