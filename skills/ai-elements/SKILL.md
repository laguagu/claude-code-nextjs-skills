---
name: ai-elements
description: Build AI chat interfaces with pre-built shadcn-style components (Message, Conversation, PromptInput, Reasoning, Sources, Tool, Artifact, CodeBlock, Suggestion, Task, Image, ChainOfThought, InlineCitation, WebPreview, Checkpoint, Plan, Queue, ModelSelector, and more). Use when adding AI chat UI to a Next.js + AI SDK app, installing AI Elements components via the CLI (`bun x ai-elements@latest add message` or `npx shadcn@latest add @ai-elements/message`), composing message displays with markdown, building prompt inputs with attachments, or rendering streaming reasoning and tool output.
---

# AI Elements

[AI Elements](https://www.npmjs.com/package/ai-elements) is a component library and custom registry built on top of [shadcn/ui](https://ui.shadcn.com/) to help you build AI-native applications faster. It provides pre-built components like conversations, messages and more.

Components are copied into the project as source, so they are owned and editable — not a black-box dependency.

## Prerequisites

- A Node.js version supported by the installed Next.js, AI SDK and CLI packages; use the strictest engine requirement
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

## Use the installed source

Inspect the generated component before composing it; APIs can change independently
of the AI SDK major. Render `UIMessage.parts` with stable message IDs, and handle
text, tool, reasoning and source parts according to the app's requirements.
Use [integration.md](references/integration.md) for the bundled v6 integration
example; use `ai-sdk-7` when the project is on v7.

Customize the owned source or pass supported props. Do not assume every compound
component forwards every HTML attribute to the same element.

## Troubleshooting

### Components render unstyled

The project is missing the shadcn/ui base layer. Tailwind 4 is CSS-first (legacy JavaScript config is possible via `@config`); `globals.css` must `@import "tailwindcss"` and define the shadcn
theme tokens in an `@theme inline` block.

### The CLI ran but nothing was added

Run it from the directory holding `package.json`, and pass both `@latest` and a component
name — use an explicit `add <component>` command and inspect the output rather than assuming the default action.

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
