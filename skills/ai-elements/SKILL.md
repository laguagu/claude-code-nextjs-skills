---
name: ai-elements
description: Build AI chat interfaces with pre-built shadcn-style components (Message, Conversation, PromptInput, Reasoning, Sources, Tool, Artifact, CodeBlock, Suggestion, Task, Image, ChainOfThought, InlineCitation, WebPreview, Checkpoint, Plan, Queue, ModelSelector, and more). Use when adding AI chat UI to a Next.js + AI SDK app, installing AI Elements components via the CLI (`bun x ai-elements@latest add message` or `npx shadcn@latest add @ai-elements/message`), composing message displays with markdown, building prompt inputs with attachments, or rendering streaming reasoning and tool output.
---

# AI Elements

[AI Elements](https://www.npmjs.com/package/ai-elements) is a component library and custom registry built on top of [shadcn/ui](https://ui.shadcn.com/) to help you build AI-native applications faster. It provides pre-built components like conversations, messages and more.

Components are copied into the project as source, so they are owned and editable — not a black-box dependency.

## Prerequisites

- [Node.js](https://nodejs.org/en/download/) 18 or later
- A [Next.js](https://nextjs.org/) project with the [AI SDK](https://ai-sdk.dev/) installed
- [shadcn/ui](https://ui.shadcn.com/) in the project — running any install command sets it up if missing

## Installing Components

Install AI Elements components using either the dedicated AI Elements CLI or the shadcn/ui CLI. Both achieve the same result: adding the selected component's code and any needed dependencies to the project.

### AI Elements CLI

```bash
# npm
npx ai-elements@latest add message
# pnpm
pnpm dlx ai-elements@latest add message
# yarn
yarn dlx ai-elements@latest add message
# bun
bun x ai-elements@latest add message
```

### shadcn CLI

```bash
# npm
npx shadcn@latest add @ai-elements/message
# pnpm
pnpm dlx shadcn@latest add @ai-elements/message
# yarn
yarn dlx shadcn@latest add @ai-elements/message
# bun
bun x shadcn@latest add @ai-elements/message
```

The CLI downloads the component's code and integrates it into the project's directory. By default, AI Elements components are added to `@/components/ai-elements/` (or whatever folder is configured in `components.json`). After running the command, the terminal confirms which files were added — proceed to import and use the component in code.

## Example

Import and compose them like any other local React component:

```tsx title="conversation.tsx"
"use client";

import {
  Message,
  MessageContent,
  MessageResponse,
} from "@/components/ai-elements/message";
import { useChat } from "@ai-sdk/react";

const Example = () => {
  const { messages } = useChat();

  return (
    <>
      {messages.map(({ role, parts }, index) => (
        <Message from={role} key={index}>
          <MessageContent>
            {parts.map((part, i) => {
              switch (part.type) {
                case "text":
                  return (
                    <MessageResponse key={`${role}-${i}`}>
                      {part.text}
                    </MessageResponse>
                  );
              }
            })}
          </MessageContent>
        </Message>
      ))}
    </>
  );
};

export default Example;
```

The example above imports the `Message` component from the AI Elements directory and composes it with the `MessageContent` and `MessageResponse` subcomponents. Style or configure the component just as you would any local component — since the code lives in your project, the component file can be opened directly for inspection or custom modifications.

## Extensibility

All AI Elements components take as many primitive attributes as possible. For example, the `Message` component extends `HTMLAttributes<HTMLDivElement>`, so you can pass any props that a `div` supports. This makes it easy to extend the component with your own styles or functionality.

## Customization

No post-install setup is needed — the Tailwind classes and scripts ship with the component. Edit the file directly to change it. For example, to remove the rounding on `Message`, drop `rounded-lg` from `components/ai-elements/message.tsx`:

```tsx title="components/ai-elements/message.tsx" highlight="8"
export const MessageContent = ({
  children,
  className,
  ...props
}: MessageContentProps) => (
  <div
    className={cn(
      "flex flex-col gap-2 text-sm text-foreground",
      "group-[.is-user]:bg-primary group-[.is-user]:text-primary-foreground group-[.is-user]:px-4 group-[.is-user]:py-3",
      className
    )}
    {...props}
  >
    <div className="is-user:dark">{children}</div>
  </div>
);
```

## Troubleshooting

### Components render unstyled

The project is missing the shadcn/ui base layer. Tailwind 4 is CSS-first — there is no
`tailwind.config.js`; `globals.css` must `@import "tailwindcss"` and define the shadcn
theme tokens in an `@theme inline` block.

### The CLI ran but nothing was added

Run it from the directory holding `package.json`, and pass both `@latest` and a component
name — a bare `ai-elements@latest` with no subcommand does not add a single component.

### Theme switching stays in light mode

shadcn/ui toggles `class="dark"` (or a `data-theme` attribute) on `<html>`. In Tailwind 4
the matching selector is declared in CSS with `@custom-variant dark`, not in a config file.
Confirm the toggle actually mutates `<html>` before suspecting the components.

### Imports fail with "module not found"

Check the file exists, then check the `@/` path alias in `tsconfig.json`:

```json title="tsconfig.json"
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"]
    }
  }
}
```

Match the alias to whatever `components.json` declares — it is not always `@/`.

Anything else: [open an issue](https://github.com/vercel/ai-elements/issues).

## Available Components

See the `references/` folder for detailed documentation on each component.
