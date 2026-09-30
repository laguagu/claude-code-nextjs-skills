---
name: icons
description: Sources icons, country flags, file-type marks and brand logos that fit the app's existing visual language. Use when adding an icon, finding an official logo, building a language switcher, or the project's icon library has no match. Covers Iconify and svgl; use frontend-design for overall visual direction and shadcn for general component installation.
license: MIT
---

# Source icons that fit

Reuse the project's icon family for ordinary UI glyphs. Choose a different source
when the mark represents a brand, country or file type, then check it in context.

## Where to look

| Need | Starting point |
|---|---|
| UI glyph | The project's existing library |
| Country flag | Iconify: `circle-flags`, `flag`, `flagpack` |
| Colour file-type mark | Iconify: `vscode-icons`, `catppuccin`, `material-icon-theme` |
| Colour brand logo or wordmark | svgl, including its light/dark variants |
| Monochrome brand logo | Iconify: `simple-icons` |
| Tech or infrastructure logo | Iconify: `logos`, `devicon`, `skill-icons` |
| A mark absent from catalogs | The organization's official brand assets |

These are search starting points, not guaranteed coverage or blanket licences.
Check the selected set's licence and the brand's usage requirements. Do not invent
a logo for a real organization when an official asset is unavailable.

## Iconify

Search at [Iconify's catalog](https://icon-sets.iconify.design/) or through its
[search API](https://iconify.design/docs/api/search.html). Results use
`prefix:name` identifiers; `prefixes` limits a query to selected sets.
Collection metadata gives licensing information. Fetch individual SVGs through
`https://api.iconify.design/{prefix}/{name}.svg` (the identifier remains `prefix:name`).
The public API needs no key; `https://api.iconify.design/collections?prefixes=<sets>`
returns metadata and licences for comma-separated sets.

The SVG flag sets `circle-flags`, `flagpack` and `flag` use lowercase ISO 3166-1
alpha-2 codes. The checked `finland` search (2026-09-30) returned only Emoji
collections, none of these three. Build the id directly: `circle-flags:fi`,
`flagpack:fi`; `flag` needs a ratio suffix (`flag:fi-4x3`, `flag:fi-1x1`), and
bare `flag:fi` is a 404. Use SVG flags rather than emoji: Windows' emoji font
has no flag glyphs and shows the letters (`FI`). For a language selector,
language names usually communicate the choice better than national flags.

Use local SVGs or build-time icon data by default. A string identifier passed to
`@iconify/react` can load missing data from the public API at runtime; merely
installing an icon-data package does not make that rendering offline. Pass or
register the data explicitly. See [React usage](https://iconify.design/docs/icon-components/react/)
for the project's chosen integration.

## svgl

Use [svgl's API docs](https://svgl.app/docs/api) to find exact titles, categories
and asset routes. It primarily holds software and brand marks, with some file
marks such as `PDF`; use Iconify for flag families and consistent file-type sets.
`?search=` matches titles; a missing title returns "SVG not found". Browse
categories through `/categories`, whose names are case-sensitive
(`/category/AI`, not `ai`). Registry names are currently slugified titles, not
asset filenames (`Hugging Face` → `hugging-face`, `Next.js` → `nextjs`,
`shadcn/ui` → `shadcnui`); confirm with `https://svgl.app/r/<name>.json`
before adding. Entries may carry light/dark routes and a separate wordmark.

For a shadcn project, its
[registry guide](https://svgl.app/docs/shadcn-ui) defines the `@svgl` namespace
at `https://svgl.app/r/{name}.json`. Follow the project's package manager and
existing registry configuration. If shadcn is absent, use the raw asset rather
than initializing a component system just to add a logo.

## Without network

Iconify and svgl are online services. Offline, search the installed icon
library (for example `node_modules/lucide-react/dist/esm/icons/`) or any
installed `@iconify-json/<prefix>/icons.json`, and reuse assets already in the
repo. For a missing brand mark, ask for the official file or use a neutral
placeholder; do not draw one.

## Integration gotchas

- Match stroke/fill, optical size and alignment to surrounding UI. Lucide uses
  a 24 px grid and 2 px stroke; Tabler and Hugeicons sit close, Material and
  Carbon read thinner. Colour file-type marks carry their own padding and often
  need one size step up. Mix by role when needed: one family for controls, one
  set for flags, one for file types. Preserve brand colours where appropriate
  rather than tinting every mark.
- Choose the variant for its actual background. Check dark and light surfaces
  if both are supported.
- Inline SVG masks, gradients and clip paths need IDs unique per rendered
  instance, with every reference updated. A brand-name suffix still collides
  when the same logo appears twice.
- Put an accessible name on icon-only controls; hide decorative SVGs next to
  equivalent text. Verify the rendered control and downloaded asset.
