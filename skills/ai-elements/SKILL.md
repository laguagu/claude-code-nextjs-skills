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

Find current component documentation through the
[AI Elements site](https://ai-sdk.dev/elements), the available AI Elements MCP,
or the matching component file in `references/`. Load only the relevant
component references; verify older bundled examples against installed source.

For installation, use the project's runner with `ai-elements@latest add <component>`
or `shadcn@latest add @ai-elements/<component>`. Check installed components and
review generated files before replacing local customization. Use `shadcn` for
registry, preset and primitive-base details.

## Integration

[Integration](references/integration.md) covers the UI/SDK boundary and v6
pitfalls. Keep stable message IDs and render supported message parts with the
generated compound components. Keep model choice, tools, credentials and
authorization on the server.

Compose the states the feature needs: streaming, completion, retry, cancellation,
attachments, approval or sources. Avoid adding components merely because the
library offers them. Preserve keyboard interaction, accessible labels and useful
scroll behavior.

When rendering fails, inspect the owned component, theme imports, semantic tokens
and actual configured aliases. Do not copy a default `tsconfig` or replace the
project's theme to fix one import.

Verify the rendered flow with real message states and the project's checks;
type correctness alone does not establish usable streaming or attachment behavior.
