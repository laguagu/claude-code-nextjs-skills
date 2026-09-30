---
name: ai-elements
description: Builds AI chat interfaces with AI Elements components copied into the project. Use when adding or composing conversations, messages, prompt inputs, attachments, reasoning, tool output or sources in an AI SDK application.
---

# AI Elements

Use AI Elements where its components fit the interaction. The generated source
belongs to the project: inspect it for the actual API and customize it deliberately.

## Project and documentation

Follow the project's package manager, aliases, shadcn configuration and AI SDK
major. Read `ai-sdk` to resolve the installed version, then the appropriate
`ai-sdk-6` or `ai-sdk-7` guidance. AI Elements and AI SDK versions can change
independently.

Read generated `components/ai-elements/<component>.tsx` first, then the
matching `references/` file and its `scripts/` examples. Use the
[AI Elements site](https://elements.ai-sdk.dev) or available AI Elements MCP
for current documentation. Load only relevant references; verify bundled
examples against installed source.

For installation, use the project's runner with `ai-elements@latest add <component>`
or `shadcn@latest add @ai-elements/<component>`. Components land in
`components/ai-elements/` under the alias configured in `components.json`; that
installed source is the offline API reference. Check installed components and
review generated files before replacing local customization. Use `shadcn` for
registry, preset and primitive-base details.

## Integration

[Integration](references/integration.md) covers the UI/SDK boundary, v6
pitfalls and the `context.tsx` patch that AI SDK 7 needs. Keep stable message
IDs and render supported message parts with the generated compound components.
Keep model choice, tools, credentials and authorization on the server.

Compose the states the feature needs: streaming, completion, retry, cancellation,
attachments, approval or sources. Avoid adding components merely because the
library offers them. Preserve keyboard interaction, accessible labels and useful
scroll behavior.

When rendering fails, inspect the owned component, theme imports, semantic tokens
and actual configured aliases. Do not copy a default `tsconfig` or replace the
project's theme to fix one import.

Verify the rendered flow with real message states and the project's checks;
type correctness alone does not establish usable streaming or attachment behavior.
