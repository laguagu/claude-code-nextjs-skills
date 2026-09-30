---
name: nextjs-shadcn
description: Builds distinctive Next.js interfaces with shadcn/ui, choosing typography, styling and purposeful visual effects for the product. Use when creating or polishing a Next.js + shadcn app, page or component, including themes, presets, backgrounds and design-system lint. Uses frontend-design for substantial visual direction and icons for asset sourcing.
---

# Next.js + shadcn/ui

Build an interface with a visual identity that fits its content, audience and task. These are design defaults, not a fixed page recipe; the user's direction and an established design system take precedence.

## Choose the visual direction

For a new view or substantial redesign, use `frontend-design` to choose the typography, palette and composition before building. Preserve a working visual system during smaller edits.

Choose fonts for the product's tone, reading density and language support. Choose a shadcn preset as a foundation, then make deliberate choices about type scale, spacing and hierarchy. Neither the default preset nor an unusual font guarantees a good design.

Keep the user's task clear:

- Cut decorative badges, repeated headings, empty marketing claims and helper text that explains the obvious.
- Keep useful status, navigation, explanations and disclosures.
- Use cards, sections and CTAs because the content needs them, rather than filling a template.
- Reuse the project's icon family. Use `icons` when sourcing new icons or brand assets; an icon does not automatically replace a clear label.

## Use atmosphere when it helps

Grid and dot patterns, soft background lights, gradients, custom shapes, textures, illustrations and video are available design tools. Use them when they suit the brief, strengthen the product's identity or clarify a section. A distinctive background can be the right choice; a quiet page can be too.

Keep effects behind content, consistent with the palette and proportionate to the page. Use available image or video generation tools when purpose-made media would improve the result, or reuse suitable real assets. Choose the asset and implementation for the task; there is no mandatory animation library or image quota.

Read [styling.md](references/styling.md) when deciding on fonts, theme customization, backgrounds, media or motion.

## Work from the actual project

Use Bun for new projects. In existing projects, follow `packageManager`, the lockfile, component conventions and configured aliases.

Inspect `components.json` and the installed components before editing. The `shadcn` skill covers component composition, CLI and registries. With the project's package runner:

```bash
bunx --bun shadcn@latest info --json
bunx --bun shadcn@latest docs <component>
```

Component APIs depend on the primitive base: Base UI uses `render` where Radix commonly uses `asChild`. Preserve the existing base and consult its docs.

Prefer documentation matching the installed Next.js version, including `node_modules/next/dist/docs/` when present. Use available Next.js dev tools for runtime errors and route context rather than relying on remembered APIs.

## Keep the integration sound

- Keep Client Component boundaries as narrow as practical; providers and interactive subtrees may need a higher boundary.
- Keep shared chrome in layouts and route content near its route. A `(protected)` route group does not enforce authorization.
- Authenticate, authorize and validate inside Server Actions and data access. Choose caching from freshness and access requirements.
- Use semantic theme tokens and existing component variants. Put deliberate design-system changes in the theme or component definitions.

Read [architecture.md](references/architecture.md) for routing, Server/Client boundaries and caching; [sidebar.md](references/sidebar.md) for shared sidebar layouts; [project-setup.md](references/project-setup.md) for scaffolding and presets.

## Verify the result

Inspect the rendered view at relevant mobile and desktop widths. Check composition, wrapping, overflow, controls and the states affected by the change. Preserve accessibility, focus and reduced-motion behavior; screenshots and DOM inspection answer different questions.

Run the project's checks. If `@shadcn/lint` is configured, use its feedback to keep the design system coherent. For a new Tailwind v4 project, or recurring theme drift, consider integrating it with the existing linter. Configure rules for the intended design; custom backgrounds and media may need deliberate exceptions. See [shadcn-platform.md](references/shadcn-platform.md) for lint setup and optional shadcn utilities.

Report what changed and what was verified.
