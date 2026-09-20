---
name: cache-components
description: "Expert guidance for Next.js Cache Components and Partial Prerendering (PPR). Use when implementing 'use cache' directive, configuring cache lifetimes with cacheLife(), tagging cached data with cacheTag(), invalidating caches with updateTag()/revalidateTag(), optimizing static vs dynamic content boundaries, evaluating experimental 'use cache: private', pass-through/interleaving patterns, GET Route Handler caching, debugging cache issues, and reviewing Cache Component implementations."
metadata:
  version: "1.0"
---

# Next.js Cache Components

Check that `cacheComponents: true` is enabled before applying these patterns.
Use the existing caching mode unless migration is requested.

Cache Components combine a prerendered shell with cached and request-time
content. Read detailed APIs in [REFERENCE.md](REFERENCE.md), recipes in
[PATTERNS.md](PATTERNS.md), and failures in [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Philosophy: Code Over Configuration

Cache Components represents a shift from **segment configuration** to **compositional code**:

| Without Cache Components                     | After (Cache Components)                  |
| --------------------------------------- | ----------------------------------------- |
| `export const revalidate = 3600`        | `cacheLife('hours')` inside `'use cache'` |
| `export const dynamic = 'force-static'` | Use `'use cache'` and Suspense boundaries |
| All-or-nothing static/dynamic           | Granular: static shell + cached + dynamic |

**Key Principle**: Components co-locate their caching, not just their data. Next.js provides build-time feedback to guide you toward optimal patterns.

## Cache boundaries

- Cache reusable results only when their freshness and authorization rules permit it.
- Read `cookies()`/`headers()` outside a plain `use cache` function. Pass the
  required serializable values as arguments; those arguments participate in the
  cache key. Authenticate before calling user-scoped cached functions.
- Put uncached I/O and request-time access below Suspense. User-specific results
  can be cached with correctly scoped keys, but sensitive data may need to stay
  uncached under the application's policy.
- `use cache: private` is experimental. It is not a compliance guarantee; check
  its current limitations before using it.

## Quick Start

### Enable Cache Components

```typescript
// next.config.ts
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  cacheComponents: true,
}

export default nextConfig
```

### Basic Usage

```tsx
// Cached component - output included in static shell
async function CachedPosts() {
  'use cache'
  const posts = await db.posts.findMany()
  return <PostList posts={posts} />
}

// Page with static + cached + dynamic content
export default async function BlogPage() {
  return (
    <>
      <Header /> {/* Static */}
      <CachedPosts /> {/* Cached */}
      <Suspense fallback={<Skeleton />}>
        <DynamicComments /> {/* Dynamic - streams */}
      </Suspense>
    </>
  )
}
```

## Reads and mutations

Prefer Server Components/Route Handlers for reads and Server Actions for
mutations. Reading inside an Action is technically possible; using Actions as a
read API can serialize client calls and is not their intended role.

Authenticate, authorize and validate mutation inputs before writing. Invalidate
the affected cache with `updateTag` for read-your-writes, or `revalidateTag` for
the required stale-while-revalidate behavior.

## Core APIs

### 1. `'use cache'` Directive

Marks code as cacheable. Can be applied at three levels:

```tsx
// File-level: All exports are cached
'use cache'
export async function getData() {
  /* ... */
}
export async function Component() {
  /* ... */
}

// Component-level
async function UserCard({ id }: { id: string }) {
  'use cache'
  const user = await fetchUser(id)
  return <Card>{user.name}</Card>
}

// Function-level
async function fetchWithCache(url: string) {
  'use cache'
  return fetch(url).then((r) => r.json())
}
```

**Important**: All cached functions must be `async`.

### 2. `cacheLife()` - Control Cache Duration

```tsx
import { cacheLife } from 'next/cache'

async function Posts() {
  'use cache'
  cacheLife('hours') // Use a predefined profile

  // Or custom configuration:
  cacheLife({
    stale: 60, // 1 min - client cache validity
    revalidate: 3600, // 1 hr - start background refresh
    expire: 86400, // 1 day - absolute expiration
  })

  return await db.posts.findMany()
}
```

**Predefined profiles**: `'default'`, `'seconds'`, `'minutes'`, `'hours'`, `'days'`, `'weeks'`, `'max'`

### 3. `cacheTag()` - Tag for Invalidation

```tsx
import { cacheTag } from 'next/cache'

async function BlogPosts() {
  'use cache'
  cacheTag('posts')
  cacheLife('days')

  return await db.posts.findMany()
}

async function UserProfile({ userId }: { userId: string }) {
  'use cache'
  cacheTag('users', `user-${userId}`) // Multiple tags

  return await db.users.findUnique({ where: { id: userId } })
}
```

### 4. `updateTag()` - Immediate Invalidation

For **read-your-own-writes** semantics. `updateTag()` is only callable from a
Server Action and throws in Route Handlers and other contexts; use
`revalidateTag(tag, 'max')` outside a Server Action:

```tsx
'use server'
import { updateTag } from 'next/cache'

export async function createPost(formData: FormData) {
  await db.posts.create({ data: formData })

  updateTag('posts') // Client immediately sees fresh data
}
```

### 5. `revalidateTag()` - Background Revalidation

For stale-while-revalidate pattern:

```tsx
'use server'
import { revalidateTag } from 'next/cache'

export async function updatePost(id: string, data: FormData) {
  await db.posts.update({ where: { id }, data })

  revalidateTag('posts', 'max') // Serve stale, refresh in background
}
```

> **⚠️ Deprecated**: The single-argument form `revalidateTag('posts')` is deprecated.
> Always pass a profile (`'max'` is recommended for stale-while-revalidate) or
> `{ expire: <seconds> }` as the second argument. For webhooks that require immediate
> expiration, use `revalidateTag(tag, { expire: 0 })`. For immediate read-your-own-writes
> in Server Actions, prefer [`updateTag()`](#4-updatetag---immediate-invalidation) instead.

## When to Use Each Pattern

| Content Type | API                 | Behavior                              |
| ------------ | ------------------- | ------------------------------------- |
| **Static**   | No directive        | Rendered at build time                |
| **Cached**   | `'use cache'`       | Included in static shell, revalidates |
| **Dynamic**  | Inside `<Suspense>` | Streams at request time               |

## Parameter Permutations & Subshells

**Critical Concept**: With Cache Components, Next.js renders ALL permutations of provided parameters to create reusable subshells.

```tsx
// app/products/[category]/[slug]/page.tsx
export async function generateStaticParams() {
  return [
    { category: 'jackets', slug: 'classic-bomber' },
    { category: 'jackets', slug: 'essential-windbreaker' },
    { category: 'accessories', slug: 'thermal-fleece-gloves' },
  ]
}
```

Next.js renders these routes:

```
/products/jackets/classic-bomber        ← Full params (complete page)
/products/jackets/essential-windbreaker ← Full params (complete page)
/products/accessories/thermal-fleece-gloves ← Full params (complete page)
/products/jackets/[slug]                ← Partial params (category subshell)
/products/accessories/[slug]            ← Partial params (category subshell)
/products/[category]/[slug]             ← No params (fallback shell)
```

**Why this matters**: The category subshell (`/products/jackets/[slug]`) can be reused for ANY jacket product, even ones not in `generateStaticParams`. Users navigating to an unlisted jacket get the cached category shell immediately, with product details streaming in.

### `generateStaticParams` Requirements

With Cache Components enabled:

1. **Must provide at least one parameter** - Empty arrays now cause build errors (prevents silent production failures)
2. **Params prove static safety** - Providing params lets Next.js verify no dynamic APIs are called
3. **Partial params create subshells** - Each unique permutation generates a reusable shell

```tsx
// ❌ ERROR with Cache Components
export function generateStaticParams() {
  return [] // Build error: must provide at least one param
}

// ✅ CORRECT: Provide real params
export async function generateStaticParams() {
  const products = await getPopularProducts()
  return products.map(({ category, slug }) => ({ category, slug }))
}
```

## Cache keys include arguments

Arguments become part of the cache key:

```tsx
// Different userId = different cache entry
async function UserData({ userId }: { userId: string }) {
  'use cache'
  cacheTag(`user-${userId}`)

  return await fetchUser(userId)
}
```

## Build-Time Feedback

Cache Components provides early feedback during development. These build errors **guide you toward optimal patterns**:

### Error: Dynamic data outside Suspense

```
Error: Accessing cookies/headers/searchParams outside a Suspense boundary
```

**Solution**: Wrap dynamic components in `<Suspense>`:

```tsx
<Suspense fallback={<Skeleton />}>
  <ComponentThatUsesCookies />
</Suspense>
```

### Error: Uncached data outside Suspense

```
Error: Accessing uncached data outside Suspense
```

**Solution**: Either cache the data or wrap in Suspense:

```tsx
// Option 1: Cache it
async function ProductData({ id }: { id: string }) {
  'use cache'
  return await db.products.findUnique({ where: { id } })
}

// Option 2: Make it dynamic with Suspense
;<Suspense fallback={<Loading />}>
  <DynamicProductData id={id} />
</Suspense>
```

### Error: Request data inside cache

```
Error: Cannot access cookies/headers inside 'use cache'
```

**Solution**: Extract runtime data outside cache boundary (see "Cache boundaries" above).

## Additional Resources

- For complete API reference, see [REFERENCE.md](REFERENCE.md)
- For common patterns and recipes, see [PATTERNS.md](PATTERNS.md)
- For debugging and troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Code Generation Guidelines

When generating Cache Component code:

1. **Always use `async`** - All cached functions must be async
2. **Place `'use cache'` first** - Must be first statement in function body
3. **Call `cacheLife()` early** - Should follow `'use cache'` directive
4. **Tag meaningfully** - Use semantic tags that match your invalidation needs
5. **Extract runtime data** - Move `cookies()`/`headers()` outside cached scope
6. **Wrap dynamic content** - Use `<Suspense>` for non-cached async components
7. **Keep sensitive data uncached when required** - Evaluate experimental private caching separately; it does not establish compliance.

## Review Checklist

When reviewing code in Cache Components projects, flag these issues:

- [ ] Data fetching without `'use cache'` where caching would benefit
- [ ] Missing tags when tag-based invalidation is required (path invalidation and expiry remain available)
- [ ] Missing `cacheLife()` (relies on defaults which may not be appropriate)
- [ ] Server Actions without `updateTag()`/`revalidateTag()` after mutations
- [ ] `updateTag()` outside a Server Action - use `revalidateTag(tag, 'max')`
- [ ] `cookies()`/`headers()` called inside `'use cache'` scope
- [ ] Dynamic components without `<Suspense>` boundaries
- [ ] **Disabled with Cache Components**: `export const revalidate` - replace with `cacheLife()` in `'use cache'`
- [ ] **Disabled with Cache Components**: `export const dynamic` - replace with Suspense + cache boundaries
- [ ] Empty `generateStaticParams()` return - must provide at least one param
- [ ] Single-argument `revalidateTag('tag')` - use two-argument form with profile or `{ expire }`
