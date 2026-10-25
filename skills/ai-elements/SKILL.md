---
name: ai-elements
description: Maintains AI chat UI built from elements.ai-sdk.dev AI Elements components already copied into the project. Use when changing or debugging those components (conversations, messages, prompt inputs, attachments, reasoning, tool output, sources). New chat UI uses the shadcn/ui AI Elements patterns (`shadcn` skill).
---

# AI Elements

Use AI Elements where its components fit the interaction. The generated source
belongs to the project: inspect it for the actual API and customize it deliberately.

vercel/ai-elements will be deprecated at the end of November 2026 (announced
2026-10-14, CLI 1.9.1). Its replacement is AI Elements from shadcn/ui
(https://ui.shadcn.com/docs/ai-elements): copy-in patterns built on Message,
Bubble, Message Scroller, Trace and Code Block. Copied files in
`components/ai-elements/` keep working. To move one onto shadcn/ui, use the
'Migrating from AI SDK Elements' prompt on its pattern page; some elements
(artifact, canvas, persona, web-preview, ...) have no replacement. For new chat
UI use the `shadcn` skill, not `ai-elements add`.

## Project and documentation

Follow the project's package manager, aliases, shadcn configuration and AI SDK
major. Read `ai-sdk` to resolve the installed version, then the appropriate
`ai-sdk-6` or `ai-sdk-7` guidance. AI Elements and AI SDK versions can change
independently.

Read generated `components/ai-elements/<component>.tsx` first, then the
matching `references/` file and its `scripts/` examples. Use the
[AI Elements site](https://elements.ai-sdk.dev) for current documentation. Load only relevant references; verify bundled
examples against installed source.

To add a missing component to an existing install, use the project's runner
with `ai-elements@latest add <component>` or
`shadcn@latest add @ai-elements/<component>`. Components land in
`components/ai-elements/` under the alias configured in `components.json`; that
installed source is the offline API reference. Check installed components and
review generated files before replacing local customization. Use `shadcn` for
registry, preset and primitive-base details.

AI Elements targets the Radix base (upstream uses style `new-york` with
`radix-ui`). On Base UI projects expect prop mismatches in prompt-input,
attachments, inline-citation and plan ([upstream #446](https://github.com/vercel/ai-elements/issues/446),
open 2026-10-11); adapt the installed copies.

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
For unstyled markdown, check the [MessageResponse setup](references/message.md#markdown-styling).

Verify the rendered flow with real message states and the project's checks;
type correctness alone does not establish usable streaming or attachment behavior.
