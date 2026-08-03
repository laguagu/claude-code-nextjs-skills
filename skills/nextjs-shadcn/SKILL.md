---
name: nextjs-shadcn
argument-hint: "[component or page]"
description: Creates Next.js frontends with shadcn/ui. Use when building React UIs, components, pages, or applications with shadcn, Tailwind, or modern frontend patterns. Also use when the user asks to create a new Next.js project, add UI components, style pages, or build any web interface — even if they don't mention shadcn explicitly.
---

# Next.js + shadcn/ui

Build distinctive, production-grade interfaces that avoid generic "AI slop" aesthetics.

## Core Principles

1. **Minimize noise** - Icons communicate; excessive labels don't
2. **No generic AI-UI** - Avoid purple gradients, excessive shadows, predictable layouts
3. **Context over decoration** - Every element serves a purpose
4. **Theme consistency** - Use CSS variables from `globals.css`, never hardcode colors

## Quick Start

```bash
bunx --bun shadcn@latest init --template next --base base
```

`--base` selects the primitive library: `base` (Base UI, the default), `radix`
(legacy projects), or `aria` (React Aria). **The same component has different
props per base**, and the docs are base-scoped
(`/docs/components/base/sidebar` vs `/docs/components/radix/sidebar`).

For a custom design system, generate a preset code in `shadcn/create` and apply it:

```bash
bunx --bun shadcn@latest init --preset <CODE> --template next
```

### Before touching an existing project

```bash
bunx --bun shadcn@latest info --json      # base, framework, aliases, installed components
bunx --bun shadcn@latest docs <component> # API reference resolved to THIS project's base
```

Run these instead of writing component code from memory. See
[references/shadcn-platform.md](references/shadcn-platform.md) for the full CLI
surface, typeset, and the shimmer/scroll-fade utilities.

## Component Rules

### Page Structure

```tsx
// page.tsx - content only, no layout chrome
export default function Page() {
  return (
    <>
      <HeroSection />
      <Features />
      <Testimonials />
    </>
  );
}

// layout.tsx - shared UI (header, footer, sidebar)
export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <Header />
      <main>{children}</main>
      <Footer />
    </>
  );
}
```

### Client Boundaries

- `"use client"` only at leaf components (smallest boundary)
- Props must be serializable (data or Server Actions, no functions/classes)
- Pass server content via `children`

### Import Aliases

Never use relative paths (`../../lib/utils`). Default to the `@/` alias
(`@/lib/utils`) in new projects. In an existing project, read `components.json`
and follow the alias style already configured — shadcn also supports Node
package imports (`#components/ui/button`). Never mix both styles.

### Style Merging

```tsx
import { cn } from "@/lib/utils";

function Button({ className, ...props }) {
  return <button className={cn("px-4 py-2 rounded", className)} {...props} />;
}
```

## File Organization

```
app/
├── (protected)/         # Auth required routes
│   ├── dashboard/
│   ├── settings/
│   ├── components/      # Route-specific components
│   └── lib/             # Route-specific utils/types
├── (public)/            # Public routes
│   ├── login/
│   └── register/
├── actions/             # Server Actions (global)
├── api/                 # API routes
├── layout.tsx           # Root layout
└── globals.css          # Theme tokens
components/              # Shared components
├── ui/                  # shadcn primitives
└── shared/              # Business components
hooks/                   # Custom React hooks
lib/                     # Shared utils
data/                    # Database queries
ai/                      # AI logic (tools, agents, prompts)
```

## Next.js 16 Features

### Async Params

```tsx
export default async function Page({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ q?: string }>;
}) {
  const { id } = await params;
  const { q } = await searchParams;
}
```

### Data Fetching vs Server Actions

**CRITICAL RULE:**
- **Server Actions** = ONLY for mutations (create, update, delete)
- **Data fetching** = In Server Components or `'use cache'` functions

`"use cache"` (and `cacheTag`/`cacheLife`/`updateTag`) requires the Cache Components opt-in flag — Next.js 16 does not enable it by default:

```ts
// next.config.ts
const nextConfig = { cacheComponents: true }
```

```tsx
// ❌ WRONG: Server Action for data fetching
"use server"
export async function getUsers() {
  return await db.users.findMany()
}

// ✅ CORRECT: Data function with caching
// data/users.ts
export async function getUsers() {
  "use cache"
  cacheTag("users")
  cacheLife("hours")
  return await db.users.findMany()
}

// ✅ CORRECT: Read cookies in Server Component directly
export default async function Page() {
  const theme = (await cookies()).get("theme")?.value ?? "light"
  return <App theme={theme} />
}
```

### Caching

```tsx
"use cache";

import { cacheTag, cacheLife } from "next/cache";

export async function getProducts() {
  cacheTag("products");
  cacheLife("hours");
  return await db.products.findMany();
}
```

### Server Actions (Mutations Only)

```tsx
"use server";

import { updateTag, revalidateTag } from "next/cache";
import { z } from "zod";

const schema = z.object({
  title: z.string().min(1),
  content: z.string(),
});

export async function createPost(formData: FormData) {
  // Always validate input
  const parsed = schema.parse({
    title: formData.get("title"),
    content: formData.get("content"),
  });

  await db.insert(posts).values(parsed);
  updateTag("posts"); // Read-your-writes
  // Or SWR-style revalidation: revalidateTag("posts", "max")
}
```

### Proxy API

Use `proxy.ts` for request interception (replaces middleware). Place at project root:

```tsx
// proxy.ts (project root, same level as app/)
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export function proxy(request: NextRequest) {
  // Auth checks, redirects, etc.
}

export const config = {
  matcher: ['/dashboard/:path*'],
}
```

## Dev Tools (next-devtools-mcp)

Next.js 16+ ships an MCP endpoint at `/_next/mcp` that exposes the dev server's
internals to coding agents. When working in a Next.js 16 project, recommend the
user add `next-devtools-mcp` to `.mcp.json`:

```json filename=".mcp.json"
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

Tools it provides (when dev server is running):

- `get_errors` — live build/runtime/type errors (esp. helpful for hydration mismatches)
- `get_logs` — dev log file path (browser console + server output)
- `get_routes` — all entry-point routes grouped by router type
- `get_page_metadata` — route, components, rendering details for a specific page
- `get_project_metadata` — project structure + dev server URL
- `get_server_action_by_id` — locate Server Action source from its hashed ID

Use these instead of asking the user to copy-paste error messages. Reference:
[nextjs.org/docs/app/guides/mcp](https://nextjs.org/docs/app/guides/mcp).

## Rendered markdown and loading states

Don't hand-roll CSS for these — shadcn ships them:

- **Rendered markdown / LLM output** → typeset. One owned CSS file, three
  variables (`--typeset-size`, `--typeset-leading`, `--typeset-flow`), one
  preset per context. Streaming-stable: new blocks don't restyle earlier ones.
  ```tsx
  <div className="typeset typeset-chat">{markdown}</div>
  ```
- **Indeterminate text state** ("Thinking…") → `className="shimmer"`. Use
  `Skeleton` only for placeholders with a known shape; don't stack both.
- **Soft scroll container edges** → `className="scroll-fade overflow-y-auto"`.

Details and the full class tables: [references/shadcn-platform.md](references/shadcn-platform.md).

## References

- **Architecture**: [references/architecture.md](references/architecture.md) - Components, routing, Suspense, data patterns, AI directory structure
- **Styling**: [references/styling.md](references/styling.md) - Themes, fonts, radius, animations, CSS variables
- **shadcn Platform**: [references/shadcn-platform.md](references/shadcn-platform.md) - Base UI vs Radix vs React Aria, CLI verbs, typeset, shimmer, scroll-fade, RTL, package imports
- **Sidebar**: [references/sidebar.md](references/sidebar.md) - shadcn sidebar with nested layouts, blocks, RTL
- **Project Setup**: [references/project-setup.md](references/project-setup.md) - bun commands, presets
- **Official shadcn skill**: `bunx --bun skills add shadcn/ui` - live project config + CLI/registry reference. Install alongside this skill; it covers CLI mechanics, this one covers conventions.
- **shadcn/ui**: [llms.txt](https://ui.shadcn.com/llms.txt) - fallback when the CLI isn't available; prefer `shadcn docs <component>`

## Package Manager

**Always use bun** in new projects, never npm or npx:

- `bun install` (not npm install)
- `bun add` (not npm install package)
- `bunx --bun` (not npx)

In an existing repo, respect the project's `packageManager` field and lockfile instead of switching to bun.
