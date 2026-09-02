# View Transitions in Next.js

## Contents

- [Setup](#setup)
- [Next.js Implementation Additions](#nextjs-implementation-additions)
- [Layout-Level ViewTransition](#layout-level-viewtransition)
- [The transitionTypes Prop](#the-transitiontypes-prop-on-nextlink)
- [Programmatic Navigation](#programmatic-navigation)
- [Server-Side Filtering](#server-side-filtering-with-routerreplace)
- [Two-Layer Pattern](#two-layer-pattern-directional--suspense)
- [loading.tsx as Suspense Boundary](#loadingtsx-as-suspense-boundary)
- [Shared Elements Across Routes](#shared-elements-across-routes)
- [Same-Route Dynamic Segment Transitions](#same-route-dynamic-segment-transitions)
- [Server Components](#server-components)

## Setup

The official Next.js docs still mark the integration experimental and require
the flag below. Because this API moves quickly, check the installed Next.js
docs/source before production use:

```js
// next.config.js
const nextConfig = {
  experimental: { viewTransition: true },
};
module.exports = nextConfig;
```

Every `<Link>` navigation runs inside `document.startViewTransition`. Any VT with `default="auto"` fires on **every** link click — use `default="none"` to prevent competing animations.

Do **not** install `react@canary` — see SKILL.md "Availability" for details.

**TypeScript projects need one more line.** Next.js swaps in a React build that exports
`ViewTransition` at runtime, but `@types/react` keeps that declaration in `canary.d.ts`,
so `next build` fails at the type check:

```
Module '"react"' has no exported member 'ViewTransition'.
```

Reference the declarations the package already ships rather than writing your own:

```ts
// types/react-canary.d.ts
/// <reference types="react/canary" />
```

---

## Next.js Implementation Additions

When following `implementation.md`, apply these additions:

**After Step 2:** Enable the experimental flag above, then verify it exists in
the installed Next.js version before continuing.

**Step 4:** Use `transitionTypes` on `<Link>` — see "The `transitionTypes` Prop" section below for usage and availability.

**After Step 6:** For same-route dynamic segments (e.g., `/collection/[slug]`), use the `key` + `name` + `share` pattern — see Same-Route Dynamic Segment Transitions below.

---

## Layout-Level ViewTransition

**Do NOT add a layout-level VT wrapping `{children}` if pages have their own VTs.** Nested VTs never fire enter/exit when inside a parent VT — page-level enter/exit will silently not work. Remove the layout VT entirely.

A bare `<ViewTransition>` in layout works only if pages have **no** VTs of their own.

**Layouts persist across navigations** — `enter`/`exit` only fire on initial mount, not on route changes. Don't use type-keyed maps in layouts.

---

## The `transitionTypes` Prop on `next/link`

No wrapper component needed, works in Server Components:

```tsx
<Link href="/products/1" transitionTypes={['transition-to-detail']}>View Product</Link>
```

Replaces the manual pattern of `onNavigate` + `startTransition` + `addTransitionType` + `router.push()`. Reserve manual `startTransition` for non-link interactions (buttons, forms).

**Availability:** `transitionTypes` is version-dependent and not part of the
stable documented surface. Enable `experimental.viewTransition: true`, then
check the installed package with `grep -r "transitionTypes" node_modules/next/dist/`.
If absent, use `startTransition` + `addTransitionType` + `router.push()` (see
Programmatic Navigation below).

---

## Programmatic Navigation

```tsx
'use client';

import { useRouter } from 'next/navigation';
import { startTransition, addTransitionType } from 'react';

function handleNavigate(href: string) {
  const router = useRouter();
  startTransition(() => {
    addTransitionType('nav-forward');
    router.push(href);
  });
}
```

---

## Server-Side Filtering with `router.replace`

For search/sort/filter that re-renders on the server (via URL params), use `startTransition` + `router.replace`. VTs activate because the state update is inside `startTransition`:

```tsx
'use client';

import { useRouter } from 'next/navigation';
import { startTransition } from 'react';

function handleSort(sort: string) {
  const router = useRouter();
  startTransition(() => {
    router.replace(`?sort=${sort}`);
  });
}
```

List items wrapped in `<ViewTransition key={item.id}>` will animate reorder. This is the server-component alternative to the client-side `useDeferredValue` pattern in `patterns.md`.

---

## Two-Layer Pattern (Directional + Suspense)

Directional slides + Suspense reveals coexist because they fire at different moments. Place the directional VT in the **page component** (not layout):

```tsx
<ViewTransition
  enter={{ "nav-forward": "slide-from-right", default: "none" }}
  exit={{ "nav-forward": "slide-to-left", default: "none" }}
  default="none"
>
  <div>
    <Suspense fallback={<ViewTransition exit="slide-down"><Skeleton /></ViewTransition>}>
      <ViewTransition enter="slide-up" default="none"><Content /></ViewTransition>
    </Suspense>
  </div>
</ViewTransition>
```

---

## `loading.tsx` as Suspense Boundary

Next.js `loading.tsx` is an implicit `<Suspense>` boundary. Wrap the skeleton in `<ViewTransition exit="...">` in `loading.tsx`, and the content in `<ViewTransition enter="..." default="none">` in the page:

```tsx
// loading.tsx
<ViewTransition exit="slide-down"><PhotoGridSkeleton /></ViewTransition>

// page.tsx
<ViewTransition enter="slide-up" default="none"><PhotoGrid photos={photos} /></ViewTransition>
```

Same rules as explicit `<Suspense>`: use simple string props (not type maps) since Suspense reveals fire without transition types.

---

## Shared Elements Across Routes

```tsx
// List page
{products.map((product) => (
  <Link key={product.id} href={`/products/${product.id}`} transitionTypes={['nav-forward']}>
    <ViewTransition name={`product-${product.id}`}>
      <Image src={product.image} alt={product.name} width={400} height={300} />
    </ViewTransition>
  </Link>
))}

// Detail page — same name
<ViewTransition name={`product-${product.id}`}>
  <Image src={product.image} alt={product.name} width={800} height={600} />
</ViewTransition>
```

---

## Same-Route Dynamic Segment Transitions

When navigating between dynamic segments of the same route (e.g., `/collection/[slug]`), the page stays mounted — enter/exit never fire. Use `key` + `name` + `share`:

```tsx
<Suspense fallback={<Skeleton />}>
  <ViewTransition key={slug} name="collection-content" share="auto" enter="auto" default="none">
    <Content slug={slug} />
  </ViewTransition>
</Suspense>
```

- `key={slug}` forces unmount/remount on change
- Use a **static** `name` (e.g. `"collection-content"`), not a per-slug name. The crossfade only forms when the old and new VTs share the *same* `name` — a per-slug name (`collection-${slug}`) gives each segment a different name, so no shared pair forms and nothing animates.
- `share="auto"` crossfades the matched pair; `enter="auto"` covers the first render where no old pair exists yet. Keep `default="none"` so unrelated transitions don't fire it.
- VT inside `<Suspense>` (without keying Suspense) keeps old content visible during loading

---

## Server Components

- `<ViewTransition>` works in both Server and Client Components
- `<Link transitionTypes>` works in Server Components — no `'use client'` needed
- `addTransitionType` and `startTransition` for programmatic nav require Client Components
