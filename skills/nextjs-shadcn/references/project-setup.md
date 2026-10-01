# Scaffolding and presets

Use Bun in new projects. In an existing repo, follow its `packageManager`, lockfile and scripts.

## New project

The shadcn CLI can scaffold a Next.js app:

```bash
bunx --bun shadcn@latest init --template next --base base
```

For a chosen visual system, obtain a preset code from [shadcn/create](https://ui.shadcn.com/create):

```bash
bunx --bun shadcn@latest init --preset <CODE> --template next
```

Pass the code through unchanged. Use the CLI's `preset decode` command when you need to inspect it. Choose fonts, style and primitive base for the product; retain an existing project's base.

For example, `b0` selects Nova, neutral colors, Lucide and Inter, with headings inheriting the body font (checked against the preset source on 2026-10-01):

```bash
bunx --bun shadcn@latest init --preset b0 --template next
```

This is an installation example, not the preset to use for every product. Choose the code for the brief in [shadcn/create](https://ui.shadcn.com/create); the available styles, fonts and icon families are summarized in [styling.md](styling.md).

Keep Bun in the scaffolded project's package setup and record the convention in its agent instructions so later sessions retain it. Preserve any framework-generated instruction block when adding that local rule.

Use `@/` as the import alias for a new standalone app unless the project calls for another convention. Follow configured aliases and shared-package boundaries in existing apps and monorepos.

## Existing project

Inspect `components.json`, theme CSS, installed components and package metadata before changing them. Use the `shadcn` skill for current CLI details.

`apply <CODE>` changes an existing project's preset; `--only theme` limits it to the theme. Preview changes where supported and review the generated diff, especially before replacing customized components.

For components, use the project's package runner with `shadcn add`. Install animation, AI, form or icon dependencies only when the feature calls for them.

## Monorepos

Follow the repository's app/shared-UI boundaries and task runner. Use the CLI's `--monorepo` option when scaffolding a monorepo, and run component changes in the appropriate app or package.

Run the generated or existing scripts for development, lint, types and build. There is no universal directory tree or test runner to impose on an established project.

Source: [shadcn CLI](https://ui.shadcn.com/docs/cli).

