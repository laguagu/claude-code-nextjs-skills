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

Sources, in order: the generated `components/ai-elements/<component>.tsx`
(the installed truth), this skill's `references/<component>.md` with its
`scripts/` examples, then the [AI Elements docs](https://elements.ai-sdk.dev).
Load only the relevant component references; verify bundled examples against
the installed source.

Install with the project's runner: `ai-elements@latest add <component...>` or
`shadcn@latest add @ai-elements/<component>`. Name the components; the
`ai-elements` CLI installs every component when none is given. Check installed
components and review generated files before replacing local customization.
Use `shadcn` for registry, preset and primitive-base details.

## Integration

[Integration](references/integration.md) covers the UI/SDK boundary and its
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
