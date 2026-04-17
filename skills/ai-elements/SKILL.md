---
name: ai-elements
description: Build AI chat interfaces with pre-built shadcn-style components (Message, Conversation, PromptInput, Reasoning, Sources, Tool, Artifact, CodeBlock, Branch, Suggestions, Task, Image, ChainOfThought, InlineCitation, WebPreview, and more). Use when adding AI chat UI to a Next.js + AI SDK app, installing AI Elements components via the CLI (`bun x ai-elements@latest add <name>` or `npx shadcn@latest add @ai-elements/<name>`), composing message displays with markdown, building prompt inputs with attachments, or rendering streaming reasoning and tool output.
argument-hint: "[component-name]"
---

# AI Elements

[AI Elements](https://www.npmjs.com/package/ai-elements) is a component library and custom registry built on top of [shadcn/ui](https://ui.shadcn.com/) to help you build AI-native applications faster. It provides pre-built components like conversations, messages and more.

Installing AI Elements is straightforward and can be done in a couple of ways. You can use the dedicated CLI command for the fastest setup, or integrate via the standard shadcn/ui CLI if you've already adopted shadcn's workflow.



## Quick Start

Here are some basic examples of what you can achieve using components from AI Elements.



## Prerequisites

Before installing AI Elements, make sure your environment meets the following requirements:

- [Node.js](https://nodejs.org/en/download/), version 18 or later
- A [Next.js](https://nextjs.org/) project with the [AI SDK](https://ai-sdk.dev/) installed.
- [shadcn/ui](https://ui.shadcn.com/) installed in your project. If you don't have it installed, running any install command will automatically install it for you.



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

## Usage

Once an AI Elements component is installed, you can import it and use it in your application like any other React component. The components are added as part of your codebase (not hidden in a library), so the usage feels very natural.

## Example

After installing AI Elements components, you can use them in your application like any other React component. For example:

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



After installation, no additional setup is needed. The component’s styles (Tailwind CSS classes) and scripts are already integrated. You can start interacting with the component in your app immediately.

For example, if you'd like to remove the rounding on `Message`, you can go to `components/ai-elements/message.tsx` and remove `rounded-lg` as follows:

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

## Why are my components not styled?

Make sure your project is configured correctly for shadcn/ui in Tailwind 4 - this means having a `globals.css` file that imports Tailwind and includes the shadcn/ui base styles.

## I ran the AI Elements CLI but nothing was added to my project

Double-check that:

- Your current working directory is the root of your project (where `package.json` lives).
- Your components.json file (if using shadcn-style config) is set up correctly.
- You're using the latest version of the AI Elements CLI by passing `@latest` and a component name:

```bash title="Terminal"
bun x ai-elements@latest add message
# or:
npx ai-elements@latest add message
```

If all else fails, feel free to open an [issue on GitHub](https://github.com/vercel/ai-elements/issues).

## Theme switching doesn’t work — my app stays in light mode

Ensure your app is using the same data-theme system that shadcn/ui and AI Elements expect. The default implementation toggles a data-theme attribute on the `<html>` element. Make sure your tailwind.config.js is using class or data- selectors accordingly:

## The component imports fail with “module not found”

Check the file exists. If it does, make sure your `tsconfig.json` has a proper paths alias for `@/` i.e.

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

## My AI coding assistant can't access AI Elements components

1. Verify your config file syntax is valid JSON.
2. Check that the file path is correct for your AI tool.
3. Restart your coding assistant after making changes.
4. Ensure you have a stable internet connection.

## Still stuck?

If none of these answers help, open an [issue on GitHub](https://github.com/vercel/ai-elements/issues) and someone will be happy to assist.

## Available Components

See the `references/` folder for detailed documentation on each component.
