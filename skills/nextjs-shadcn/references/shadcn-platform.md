# shadcn Platform

The parts of shadcn that are not individual components: which primitive base to
build on, the CLI verbs worth knowing, and the CSS-level systems (typeset,
shimmer, scroll-fade).

## Choosing a base (do this first)

shadcn components ship on three primitive libraries: Base UI, Radix, and React
Aria. **Base UI is the default.** The choice is per-project and set at `init` —
components installed later inherit it.

```bash
bunx --bun shadcn@latest init --template next --base base   # Base UI (default)
bunx --bun shadcn@latest init --template next --base radix  # Radix (legacy projects)
bunx --bun shadcn@latest init --template next --base aria   # React Aria
```

| Base | Pick it when |
|------|-------------|
| `base` | New projects. Default since July 2026, most actively developed, gets new components first. |
| `radix` | Existing codebase already on Radix, or a dependency expects Radix primitives. |
| `aria` | Accessibility/interaction requirements beyond the defaults — React Aria's behavior hooks. |

**Why this matters for generated code:** the same component name has different
props and sub-components per base. Docs are base-scoped too —
`ui.shadcn.com/docs/components/base/sidebar` vs `.../radix/sidebar`. Never write
component code from memory without knowing the project's base.

The difference that bites most often: **Base UI composes through a `render`
prop, Radix through `asChild`.**

```tsx
// Base UI (default) — element goes in render, children stay as children
<SidebarMenuButton render={<Link href="/inbox" />}>
  <Inbox />
  <span>Inbox</span>
</SidebarMenuButton>

// Radix — element wraps the children
<SidebarMenuButton asChild>
  <Link href="/inbox">
    <Inbox />
    <span>Inbox</span>
  </Link>
</SidebarMenuButton>
```

Read the base from `components.json` (or `shadcn info --json`) before editing an
existing project.

`migrate radix` does **not** switch a project from Radix to Base UI — it rewrites
`@radix-ui/react-*` imports to the single `radix-ui` package. Radix → Base UI is
a component-at-a-time migration driven by the official shadcn skill:

```bash
bunx --bun skills add shadcn/ui
# then ask the agent: "migrate accordion to base-ui"
```

Both libraries stay installed while you work, each component lands in its own
commit, and every run writes a report to `.migration/<component>.md`.

## CLI verbs beyond `add`

`add` and `init` are the familiar ones. These four are what make the CLI useful
to an agent:

```bash
shadcn info --json              # project config: framework, base, tailwind, aliases, installed components
shadcn docs button              # API reference for a component, resolved to THIS project's base
shadcn docs button --json       # machine-readable, for piping into context
shadcn view button card         # inspect registry item source before installing
shadcn search @shadcn -q chart  # search a registry namespace
```

**Prefer `shadcn docs <component>` over recalling props from memory or fetching
`llms.txt`** — it resolves against the project's actual base and version. Use
`shadcn view` before `add` when you are unsure what a registry item pulls in.

Other verbs: `add <component> --diff` (upstream changes to an installed
component — the standalone `diff` command is deprecated), `apply <preset>`
(apply a preset to an existing project; `--only theme,font` for just those
parts), `preset decode|resolve|url|open` (inspect a preset code), `build`
(generate registry JSON), `migrate` (`icons`, `rtl`, `radix`), `eject` (inline
`shadcn/tailwind.css` and drop the `shadcn` dependency).

### `migrate icons`

Swapping icon libraries across a whole project is a single command:

```bash
bunx --bun shadcn@latest migrate icons --from lucide --to phosphor
```

## The official shadcn skill

shadcn publishes its own agent skill, which injects live project config
(`shadcn info --json`) plus the full CLI and registry reference:

```bash
bunx --bun skills add shadcn/ui
```

It activates when the project has a `components.json`. It covers CLI mechanics
and registry authoring — **this skill covers project conventions, architecture,
and Next.js integration instead.** Install both; don't duplicate CLI reference
material here.

There is also an MCP server for registry search and install from within the
editor — wire it into Claude Code with
`bunx --bun shadcn@latest mcp init --client claude`.

## Typeset — styling rendered markdown

One CSS file you own that styles headings, paragraphs, lists, tables and code
inside a wrapper class. Replaces hand-written `prose`-style overrides and
per-context markdown CSS.

**Use it for:** chat message bodies, docs pages, blog posts, LLM-streamed
markdown — anywhere you render HTML you did not author.

Typeset is **not** part of `init` and has no `add` command. Generate the file in
the builder at [ui.shadcn.com/typeset](https://ui.shadcn.com/typeset), drop it
next to your main CSS, and import it after Tailwind:

```css
/* app/globals.css */
@import "tailwindcss";
@import "./typeset.css";
```

Three variables drive the whole rhythm; everything else derives from them:

```css
.typeset {
  --typeset-font-body: inherit;
  --typeset-font-heading: var(--font-heading);
  --typeset-font-mono: var(--font-mono);
  --typeset-size: 1em;      /* base text size */
  --typeset-leading: 1.75;  /* line-height */
  --typeset-flow: 1.25em;   /* space between blocks */
}
```

Define one preset per context and apply both classes:

```css
.typeset-docs {
  --typeset-size: 15px;
  --typeset-leading: 1.75;
  --typeset-flow: 1.25em;
}

.typeset-chat {
  --typeset-leading: 1.6;
  --typeset-flow: 1em;   /* tighter — chat bubbles are short */
}
```

```tsx
<div className="typeset typeset-chat">
  <Response>{message}</Response>
</div>
```

It is container-aware (sizes to its container, not just the viewport) and
**streaming-stable**: appending a new block does not restyle blocks already
rendered above it. That property is the reason to prefer it over ad-hoc CSS in
streaming chat UIs.

## Shimmer — loading and processing text

CSS-only animated sweep across text. No component, no JS.

```tsx
<p className="shimmer text-muted-foreground">Generating response…</p>
```

| Class | Effect |
|-------|--------|
| `shimmer-color-<color>` | Highlight color, e.g. `shimmer-color-blue-500/60` |
| `shimmer-duration-<ms>` | Sweep speed (default 2000) |
| `shimmer-spread-<n>` | Width of the highlight band |
| `shimmer-angle-<deg>` | Tilt (default 20) |
| `shimmer-once` | Single sweep instead of looping |
| `shimmer-reverse` | Reverse direction |

Adapts to the element's text color, brightens in dark mode, respects
`prefers-reduced-motion` and RTL automatically.

**Use shimmer for indeterminate text states** ("Thinking…", "Searching…") and
`Skeleton` for layout placeholders with known shape. Don't stack both.

## Scroll-fade — soft scroll container edges

Masks the content itself at the edges of a scroll container rather than
overlaying a gradient, so it works on any background.

```tsx
<div className="scroll-fade overflow-y-auto">{/* content */}</div>
```

| Class | Effect |
|-------|--------|
| `scroll-fade` / `scroll-fade-y` | Vertical |
| `scroll-fade-x` | Horizontal |
| `scroll-fade-t` / `-b` / `-l` / `-r` | Single edge |
| `scroll-fade-s` / `-e` | Start/end edge (RTL-aware) |
| `scroll-fade-<n>` | Fade depth on the spacing scale |
| `scroll-fade-none` | Disable |

Scroll-aware: the top edge stays crisp until you scroll away from it.

Both `shimmer` and `scroll-fade` come from `shadcn/tailwind.css`, which `init`
wires up. In a project that skipped it:

```css
@import "tailwindcss";
@import "shadcn/tailwind.css";
```

## RTL support

Sidebar and the CSS utilities are RTL-aware. Opt in at init with `--rtl`,
retrofit an existing project with `migrate rtl`, and pass `dir` on the `Sidebar`
component. Prefer logical utilities (`ms-`/`me-`, `scroll-fade-s/-e`)
over physical ones (`ml-`/`mr-`) in any project that might need it.

## Package imports (alias alternative)

Projects may use Node package imports instead of `tsconfig.json` paths:

```json
// package.json
{ "imports": { "#components/*": "./src/components/*.tsx", "#lib/*": "./src/lib/*.ts" } }
```

```tsx
import { Button } from "#components/ui/button";
import { cn } from "#lib/utils";
```

Requires `moduleResolution: "bundler"` and `resolvePackageJsonImports: true`, and
the matching `aliases` block in `components.json`. The CLI rewrites imports to
whichever alias style is configured.

**Default to `@/` for new projects.** In an existing project, read
`components.json` and follow what is already there — never mix both styles.

## Registries

Beyond `@shadcn`, the CLI resolves namespaced registries (`@acme/button`),
including private and GitHub-hosted ones. If you author a registry with more
than a few hundred items, implement
[dynamic search](https://ui.shadcn.com/docs/registry/dynamic-search) so
`shadcn search` filters server-side instead of downloading the whole catalog.
Not needed for consuming registries.
