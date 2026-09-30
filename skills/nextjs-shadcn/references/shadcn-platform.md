# shadcn utilities and design-system lint

Use the `shadcn` skill and [current CLI docs](https://ui.shadcn.com/docs/cli) for component management, presets and registries. This reference covers optional tools around the components.

## Project-aware APIs

Inspect the primitive base, aliases, theme and installed components through `components.json` and `shadcn info --json`. `shadcn docs <component>` resolves to the project's base.

Base UI's `render` and Radix's `asChild` are different composition APIs. Preserve the project's base unless migration is in scope. `migrate radix` consolidates Radix package imports; it does not migrate components to Base UI.

Use the existing alias convention, including Node package imports when configured. Prefer logical spacing utilities for RTL-aware layouts.

To switch icon family across installed components, `shadcn migrate icons --from <id> --to <id>` takes the library ids `lucide`, `tabler`, `hugeicons`, `phosphor` and `remixicon`. Hugeicons now ships as `@hugeicons/react` with `@hugeicons/core-free-icons`; `hugeicons-react` is deprecated.

## Rendered markdown and loading

[Typeset](https://ui.shadcn.com/docs/typeset) provides owned CSS for rendered markdown, docs or streaming content. Generate `typeset.css` in its builder, import it after Tailwind and use the builder's `typeset`/preset wrapper classes; it is not installed by `init`. Use it when it fits the content rather than recreating a typography system for every message.

The `shimmer` and `scroll-fade` utilities come from `shadcn/tailwind.css` in projects that import it:

- `shimmer` can communicate an indeterminate text state.
- `scroll-fade` can soften a scroll container's content edges.
- `no-scrollbar` hides a scrollbar when that is appropriate for the interaction.

Check the actual stylesheet before using utilities in an older project. Keep loading feedback useful and scroll affordances discoverable.

## Design-system lint

[`@shadcn/lint`](https://github.com/shadcn-ui/lint) supports Tailwind v4 design systems through ESLint or Oxlint. It can find theme drift and suggest existing tokens, variants or sizes.

Use the existing UI linter. In a new project or one with recurring styling drift, consider adding the plugin; do not introduce it for every small UI edit.

For setup, read the current [SETUP.md](https://github.com/shadcn-ui/lint/blob/main/SETUP.md) and framework documentation. Register the plugin while preserving existing parsers, scripts, rules and ignores. Installing the plugin and enabling policies are separate choices; setup alone does not enforce a design system.

Choose policies for the actual project:

| Rule | Useful check |
|---|---|
| `no-restyle` | Component instances overriding the component's intended styling |
| `no-raw-colors` | Palette colors where semantic theme tokens should be used |
| `no-arbitrary-values` | Off-scale spacing or sizes |
| `no-inline-styles` | Styles outside the project's chosen styling conventions |
| `require-static-classes` | Dynamic classes the tooling cannot read |
| `no-unknown-classes` | Classes Tailwind cannot generate |

Use contracts and scoped exceptions where deliberate customization belongs: component source, custom patterns, dynamic geometry or media layers. A blanket ban on arbitrary values or inline styles can defeat a valid visual design. Resolve the intent before changing a policy.

Existing projects can adopt selected rules gradually instead of rewriting unrelated UI. Token suggestions are candidates, not semantic decisions: a nearby chart color may be wrong for muted body text.

Run the project's lint command and fix errors introduced by the change. Distinguish configuration errors, existing findings and new findings. Browser verification remains necessary; lint does not judge composition or whether a badge is useful.

Further configuration: [documentation](https://github.com/shadcn-ui/lint/tree/main/docs).
