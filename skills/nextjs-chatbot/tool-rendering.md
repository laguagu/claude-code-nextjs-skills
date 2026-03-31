# Tool UI Rendering

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

```tsx
// Inside renderToolPart() in chat-message.tsx

if (part.type === "tool-searchServices") {
  const toolPart = part as typeof part & { output?: SearchServicesOutput };
  return renderToolState(
    {
      state: toolPart.state as ToolState,
      output: toolPart.output,
      errorText: toolPart.errorText,
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

For tools that need special approval states (HITL), don't use this factory — handle each state manually. See [hitl.md](hitl.md).

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

## PII / phone number sanitization

Sanitize at **read-time** (when the tool returns data), not just at write-time. This ensures data imported from external sources never leaks through tool outputs even if the import-time sanitization was incomplete.

```ts
// lib/ai/tools/sanitize.ts
export function stripPhoneNumbers(text: string): string {
  // Remove patterns like +358 40 123 4567, (09) 1234567, etc.
  return text.replace(/(\+?\d[\d\s\-().]{6,}\d)/g, "[phone removed]");
}

export function sanitizeContact(contact: ContactRow): SanitizedContact {
  return {
    ...contact,
    phone: undefined,  // never expose phone
    // Apply stripPhoneNumbers to any text fields that might contain phone numbers
    notes: contact.notes ? sanitizeOptionalText(contact.notes) : undefined,
  };
}
```

Apply sanitization inside the tool's `execute` function before returning output, not in the UI layer.

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

