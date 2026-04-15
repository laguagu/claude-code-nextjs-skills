# Tool UI Rendering

## Contents

- [Core principle: one component per tool](#core-principle-one-component-per-tool)
- [renderToolState factory](#rendertoolstate-factory)
- [Using the factory](#using-the-factory)
- [Tool part type naming](#tool-part-type-naming)
- [Collapsible for large result sets](#collapsible-for-large-result-sets)
- [Output type definitions](#output-type-definitions)
- [Source URL parts (web search)](#source-url-parts-web-search)

## Core principle: one component per tool

Don't render tool outputs as generic JSON. Each tool gets a dedicated React component that presents its data meaningfully. The `renderToolState<T>` factory handles the common loading/error/empty states so each tool only needs to implement the happy-path render.

## renderToolState factory

```ts
// components/chat-message.tsx

type ToolState = "input-streaming" | "input-available" | "output-available" | "output-error";

interface ToolPartConfig<T> {
  state: ToolState;
  output?: T;
  errorText?: string;
  loadingMessage: string;
  errorPrefix: string;
  isEmpty: (output: T) => boolean;
  render: (output: T) => ReactNode;
  containerClass?: string;
  collapsibleLabel?: (output: T) => string;  // if set, wraps output in collapsible
}

function renderToolState<T>(config: ToolPartConfig<T>, index: number): ReactNode {
  const { state, output, errorText, loadingMessage, errorPrefix, isEmpty, render,
          containerClass = "w-full", collapsibleLabel } = config;

  if (state === "input-streaming" || state === "input-available") {
    return <Shimmer key={index}>{loadingMessage}</Shimmer>;
  }

  if (state === "output-available" && output) {
    if (isEmpty(output)) return null;
    const content = <div className={`py-2 ${containerClass}`}>{render(output)}</div>;
    if (collapsibleLabel) {
      return (
        <ToolCollapsible key={index} label={collapsibleLabel(output)}>
          {content}
        </ToolCollapsible>
      );
    }
    return <div key={index}>{content}</div>;
  }

  if (state === "output-error") {
    return <div key={index} className="text-destructive text-sm">{errorPrefix}: {errorText}</div>;
  }

  return null;
}
```

## Using the factory

When `useChat<AgentUIMessage>()` is wired up (see `/ai-sdk` type-safe-agents), `part.type === "tool-searchServices"` narrows the type automatically — no `as` casts needed:

```tsx
// Inside renderToolPart() in chat-message.tsx
// message: AgentUIMessage  (from useChat<AgentUIMessage>)

if (part.type === "tool-searchServices") {
  // part.output, part.state, part.errorText are all fully typed here
  return renderToolState(
    {
      state: part.state,
      output: part.state === "output-available" ? part.output : undefined,
      errorText: part.state === "output-error" ? part.errorText : undefined,
      loadingMessage: "Searching services…",
      errorPrefix: "Error searching services",
      isEmpty: (o) => o.services.length === 0,
      render: (o) => <ServiceList services={o.services} total={o.total} />,
      collapsibleLabel: (o) => `${o.total} service${o.total !== 1 ? "s" : ""} found`,
    },
    index,
  );
}
```

**Without InferAgentUIMessage** (fallback if agent type is not exported), use `UIToolInvocation<typeof myTool>` from the tool definition file instead of runtime `as` casts — see `/ai-sdk` type-safe-agents for both patterns.

For tools that need special approval states (HITL), don't use this factory — handle each state manually. See [hitl.md](hitl.md).

> **Multi-tool flicker fix.** For multi-tool agents, remove per-tool shimmers from `renderToolPart` (return `null` for loading states). Render one shimmer at message level gated on `isStreaming && !hasText`, with a label computed from parts: pending tool → its label, all complete → "Composing answer…", no tools yet → `null` (widget handles "Thinking…"). This avoids mount/unmount flicker between sequential tool calls.
>
> **"Thinking…" placement.** The initial "Thinking…" shimmer must render inside `<Message from="assistant"><MessageContent>`, not as a bare div — otherwise layout shifts when the real message appears. Match `text-xs` + `py-1` sizing.
>
> **Dedup + shimmer bug.** If a detail tool dedups against a prior search tool's output, suppress its shimmer during loading too — check `allParts` for a matching parent-tool `output-available` at the top of `renderToolPart`.

## Tool part type naming

AI SDK v6 names tool parts as `tool-{toolName}` where `toolName` matches the key in the agent's `tools` object:

```ts
// Agent
const tools = {
  searchServices: searchServicesTool,  // part.type === "tool-searchServices"
  web_search: webSearchTool,            // part.type === "tool-web_search"
};
```

Check for tool parts:
```ts
const toolParts = message.parts.filter(part => part.type.startsWith("tool-"));
```

## Collapsible for large result sets

Use `collapsibleLabel` when a tool can return many items (lists, search results). Keeps the chat readable.

```tsx
function ToolCollapsible({ label, children }: { label: string; children: ReactNode }) {
  const [open, setOpen] = useState(false);
  return (
    <CollapsiblePrimitive.Root open={open} onOpenChange={setOpen}>
      <CollapsiblePrimitive.Trigger>
        <IconChevronDown className={open ? "" : "-rotate-90"} />
        {label}
      </CollapsiblePrimitive.Trigger>
      <CollapsiblePrimitive.Content>{children}</CollapsiblePrimitive.Content>
    </CollapsiblePrimitive.Root>
  );
}
```

## Output type definitions

Define output types in a shared file so the UI component and tool stay in sync:

```ts
// lib/ai/tools/types.ts
export type SearchServicesOutput = {
  services: Service[];
  total: number;
};

export type GetContactOutput = {
  contacts: Contact[];
};

// Used in chat-message.tsx imports:
import type { SearchServicesOutput, GetContactOutput } from "@/lib/ai/tools/types";
```

## Source URL parts (web search)

Web search results come as `source-url` parts, not tool-invocation parts. Collect them separately:

```ts
const sources = message.parts
  .filter((p): p is { type: "source-url"; url: string; title?: string } => p.type === "source-url");
```

Use the `Sources` / `SourcesTrigger` / `SourcesContent` components from ai-elements to render them. See `/ai-elements` for component details.

