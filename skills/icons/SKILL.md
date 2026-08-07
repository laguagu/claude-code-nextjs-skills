---
name: icons
description: Find, fetch, and install the right icon or logo from the right source — brand marks, country flags, file-type icons (PDF, DOCX, ZIP), and UI glyphs — and keep them visually consistent with the app. Use when the project's icon library has no match, when svgl comes up empty, or when the user asks for a flag, a file-type badge, a brand logo, or just "an icon for X". Covers the Iconify search API (200k+ icons across flags, file types, logos and UI sets), the svgl shadcn registry for full-colour brand logos, family and stroke-weight matching so a borrowed icon does not look pasted in, and why svgrepo and flaticon cannot be fetched programmatically. Triggers on "lisää ikoni", "maan lippu", "flag icon", "PDF icon", "file type icon", "brand logo", "sign in with Google/GitHub", "language switcher", "svgl", "iconify", "find an icon". For overall visual direction rather than sourcing one specific mark, use ui-signature; for installing shadcn components generally, use shadcn.
license: MIT
---

# Sourcing icons

An icon is wrong when it is the wrong *family*, not when it is the wrong shape. Pick the
source by what kind of mark it is, then match it to what the app already uses.

## Route by mark type

| Need | Source | Why |
|---|---|---|
| App UI glyph (menu, upload, search) | project's existing library — Lucide in shadcn projects | never add a second family for a glyph the current one has |
| Country flag | Iconify `circle-flags` / `flag` / `flagpack` | real flag geometry, MIT, no emoji-font dependency |
| File type (PDF, DOCX, ZIP) | Iconify `vscode-icons` / `catppuccin` / `material-icon-theme` (colour), or `lucide:file-text` (mono) | pick colour or mono to match the surrounding UI, not both |
| Brand logo, full colour, light/dark variants | svgl | curated, has wordmarks and theme variants |
| Tech / infra logo (OpenShift, Docker, Postgres, Redis) | Iconify `logos` (1800+, CC0), `devicon`, `skill-icons` | svgl has almost none of these; `logos` covers the whole stack in colour |
| Brand logo, monochrome long tail | Iconify `simple-icons` (3400+, CC0) | covers brands svgl does not |
| Anything else | Iconify search across all sets | 200k+ icons, one API |

Check the project's own library first: `lucide:file-text`, `lucide:flag`, `lucide:file` and
friends exist, and one family stays one family.

## Iconify — the general engine

Public API, no auth, no key. Search returns `prefix:name` ids.

```bash
# search everything
curl -s "https://api.iconify.design/search?query=pdf&limit=32"

# constrain to sets you actually want (this is the important flag)
curl -s "https://api.iconify.design/search?query=pdf&prefixes=vscode-icons,catppuccin,lucide"

# what is in a set / who owns the licence
curl -s "https://api.iconify.design/collections?prefixes=circle-flags,simple-icons"

# fetch the SVG itself
curl -s "https://api.iconify.design/circle-flags:fi.svg" -o public/flags/fi.svg
```

Browse visually at `https://icon-sets.iconify.design` when the user should choose. The
`collections` response carries each set's licence — nearly all of them are permissive;
**Twemoji is CC BY 4.0 and needs visible attribution**, which is the one that costs you
something.

Iconify SVGs come out at `width="1em" height="1em"`, and monochrome sets use `currentColor`
— so `className="size-4 text-muted-foreground"` just works in Tailwind. Colour sets
(`vscode-icons`, `circle-flags`, `twemoji`) ignore `currentColor` by design.

### Getting them into the project

**Default: write the SVG to a file and inline it.** No runtime dependency, no network call,
no bundle growth beyond the markup.

```bash
curl -s "https://api.iconify.design/vscode-icons:file-type-pdf2.svg" -o components/icons/pdf.svg
```

Only reach for a package when the project needs dozens of icons from one set:

- `@iconify/react` renders `<Icon icon="circle-flags:fi" />` but **fetches from the Iconify
  API at runtime** — an external request per icon set, on every visitor. Do not ship that
  to production without saying so; pair it with `@iconify-json/<prefix>` offline data, or
  skip it.
- `unplugin-icons` + `@iconify-json/<prefix>` compiles icons in at build time. This is the
  right choice for a bundler-based project pulling in a whole set.

## svgl — brand logos

Still the best source for product and company logos in colour, with light/dark variants.

```bash
bunx --bun shadcn@latest add https://svgl.app/r/<name>.json     # per icon
bunx --bun shadcn@latest add @svgl/<name>                       # if components.json has the @svgl registry
```

Several names in one command, space-separated. `components.json` must exist — if it does
not, stop and tell the user to run `bunx --bun shadcn@latest init` first.

Resolve the exact name before installing:

- `https://api.svgl.app?search=<query>` — search
- `https://api.svgl.app/categories` then `https://api.svgl.app/category/<category>` — browse
- `https://api.svgl.app/svg/<name>.svg` — raw markup

svgl is **software and brand logos only**. Its categories are Software, Framework, AI,
Library, Payment, Design and similar — there are no flags, no file types, no UI glyphs.
`?search=finland` returns `SVG not found`, and that is expected, not a bug: switch to
Iconify rather than retrying svgl with a different phrasing.

Docs: https://svgl.app/docs/shadcn-ui

## Making a borrowed icon fit

A single icon from a foreign family is the most common tell of pasted-in work. Match, in
this order:

1. **Stroke vs fill** — do not drop a filled icon into an outline set. Most Iconify sets
   ship both (`teenyicons:pdf-outline` / `teenyicons:pdf-solid`, `mingcute:pdf-line` /
   `mingcute:pdf-fill`); take the variant that matches.
2. **Stroke width and grid** — Lucide is 24px grid, 2px stroke. Tabler and Hugeicons sit
   close enough to pass; Material and Carbon do not, they read thinner and boxier.
3. **Colour** — a mono icon inherits `currentColor`; a colour icon is a *logo-like object*
   and needs the same treatment as a logo (own size, own alignment, not tinted).
4. **Optical size** — colour file-type icons carry their own padding and look smaller at
   the same box; bump one step (`size-5` against a row of `size-4`) and check by eye.

When mixing is unavoidable, mix by *category*, not per icon: all flags from one flag set,
all file types from one file-type set, all UI glyphs from the project library.

**Give every icon an accessible name or hide it.** An icon-only button is unlabelled to a
screen reader unless you add `aria-label` on the button — the SVG's own title does not
substitute. An icon sitting next to text is decorative and repeats what the text already
says: `aria-hidden="true"`. Icon component libraries do not do this for you; inlined raw
SVG certainly does not.

### Flags specifically

- Never use emoji flags (🇫🇮) when Windows is in the audience — Segoe UI Emoji ships no flag
  glyphs, so they render as two letters (`FI`). They look fine on macOS and iOS, which is
  exactly why this ships broken.
- `circle-flags` for avatar-style circles, `flagpack` for rounded rectangles with a border,
  `flag` (flag-icons) for plain rectangles. Pick one and stay in it.
- **Do not search for the country name** — `?query=finland` returns only emoji sets
  (`twemoji:flag-finland`, `openmoji:…`), never the real flag sets, because those are
  indexed by ISO code. Construct the id directly from ISO 3166-1 alpha-2, lowercase:
  `circle-flags:fi`, `flagpack:se`. `flag` needs an explicit ratio suffix —
  `flag:fi-4x3` or `flag:fi-1x1`; bare `flag:fi` is a 404.
- Language flags are politically loaded — for a language switcher prefer the language name
  over a flag.

### JSX conversion

Inlining raw SVG into JSX: `stroke-width` → `strokeWidth`, `class` → `className`, `style`
strings → objects, `<style>` block rules inlined onto elements.

**Rename every `id` per mark.** Iconify serves the *same* mask id to every icon in a set —
`circle-flags:fi` and `circle-flags:se` both arrive as `<mask id="SVGuywqVbel">`. Inline
both into one language switcher and the second mask wins for both flags. Suffix them
(`SVGmask-fi`, `SVGmask-se`) and update the matching `mask="url(#…)"` reference. Same trap
with gradients in colour logos.

## When nothing is found — svgrepo, flaticon

Both come up in searches and **neither can be used by an agent**:

- `svgrepo.com` returns HTTP 429 to programmatic requests, browser user-agent or not. No
  public API.
- `flaticon.com` returns 403. Its Freepik API needs a paid key, and the free tier requires
  visible attribution in the shipped product.

If the user wants an icon from one of these, they must download it in the browser
themselves. Ask them to drop the `.svg` file in the project and say where; do not attempt
scraping workarounds. Before using it, check the per-icon licence — svgrepo mixes CC0, MIT,
CC BY and non-commercial packs on the same site, and flaticon's free tier is
attribution-required. That mixed licensing plus mixed drawing style is the reason to treat
both as a last resort rather than a first stop.

Better fallbacks before giving up on Iconify: search a synonym (`document` for `file`,
`invoice` for `receipt`), search unprefixed to see every set, or browse the nearest
category at icon-sets.iconify.design. 200k icons is usually enough.

**Local organisations, universities and public bodies are in no icon set at all** — CSC,
Haaga-Helia and their kind return nothing from svgl or Iconify, and that is the expected
answer, not a failed search. Ask the user for the official asset, or use a lettermark in a
circle. Never invent a logo for a real organisation.
