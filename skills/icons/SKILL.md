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

Public API, no key; results use `prefix:name` identifiers
([search docs](https://iconify.design/docs/api/search.html), visual catalog at
[icon-sets.iconify.design](https://icon-sets.iconify.design/)):

```bash
curl -s "https://api.iconify.design/search?query=pdf&prefixes=vscode-icons,catppuccin"
curl -s "https://api.iconify.design/collections?prefixes=circle-flags,simple-icons"  # licence per set
curl -s "https://api.iconify.design/circle-flags:fi.svg" -o fi.svg
```

SVGs come at `width="1em" height="1em"`; monochrome sets draw with
`currentColor`, colour sets keep their own fills.

Flag sets are indexed by lowercase ISO 3166-1 alpha-2 code, so `?query=finland`
returns only emoji sets. Build the id: `circle-flags:fi`, `flagpack:fi`,
`flag:fi-4x3` or `flag:fi-1x1` (bare `flag:fi` is a 404). Emoji flags render as
two letters in Chromium on Windows; use SVG flags. For a language selector,
language names usually communicate the choice better than national flags.

Use local SVGs or build-time icon data by default. A string identifier passed to
`@iconify/react` can load missing data from the public API at runtime; merely
installing an icon-data package does not make that rendering offline. Pass or
register the data explicitly. See [React usage](https://iconify.design/docs/icon-components/react/)
for the project's chosen integration.

## svgl

Software and brand logos only ([API docs](https://svgl.app/docs/api)):

- `https://api.svgl.app?search=<brand>` matches brand names; flags, file types
  and concepts return `SVG not found`, so switch to Iconify rather than rephrasing.
- `https://api.svgl.app/categories`, then `/category/<Category>` with the
  spelling from that list (`/category/ai` is a 404; `AI` works).
- Each entry's `route` is a URL or a `{light, dark}` pair; some add a `wordmark`.
  Use those URLs for the raw SVG.

For a shadcn project, the [registry guide](https://svgl.app/docs/shadcn-ui)
maps `"@svgl": "https://svgl.app/r/{name}.json"` under `registries` in
`components.json`; then `shadcn add @svgl/<name>` with the project's runner.
Registry names derive from the title, not the route filename (`Hugging Face` →
`hugging-face`, `Next.js` → `nextjs`); confirm `https://svgl.app/r/<name>.json`
returns 200 first. If shadcn is absent, use the raw asset rather than
initializing a component system just to add a logo.

## Without network access

Use what is installed: the project's icon library, `@iconify-json/<prefix>`
packages (`icons.json` holds names and SVG bodies, `info.json` the licence) and
assets already in the repo. Otherwise ask the user for the official file.

## Integration gotchas

- Match stroke/fill, optical size and alignment to surrounding UI. Mix by role
  when needed: one family for controls, one set for flags, one for file types.
  Preserve brand colours where appropriate rather than tinting every mark.
- Choose the variant for its actual background. Check dark and light surfaces
  if both are supported.
- Inline SVG masks, gradients and clip paths need IDs unique per rendered
  instance, with every reference updated. A brand-name suffix still collides
  when the same logo appears twice.
- Put an accessible name on icon-only controls; hide decorative SVGs next to
  equivalent text. Verify the rendered control and downloaded asset.
