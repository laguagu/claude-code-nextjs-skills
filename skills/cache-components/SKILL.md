---
name: cache-components
description: "Expert guidance for Next.js Cache Components and Partial Prerendering (PPR). Use when implementing 'use cache' directive, configuring cache lifetimes with cacheLife(), tagging cached data with cacheTag(), invalidating caches with updateTag()/revalidateTag(), optimizing static vs dynamic content boundaries, managing 'use cache: private' for compliance scenarios, pass-through/interleaving patterns, GET Route Handler caching, debugging cache issues, and reviewing Cache Component implementations."
argument-hint: "[pattern or question]"
---

# Next.js Cache Components

> **Auto-activation**: Activate this skill automatically in Next.js projects that have
> `cacheComponents: true` in `next.config.ts`/`next.config.js`. When detected, apply Cache
> Components patterns to all Server Component authoring, data fetching, and caching decisions.

## Project Detection

When starting work in a Next.js project, check if Cache Components are enabled:

```bash
# Check next.config.ts or next.config.js for cacheComponents
grep -r "cacheComponents" next.config.* 2>/dev/null
```

If `cacheComponents: true` is found, apply this skill's patterns proactively when:

- Writing React Server Components
- Implementing data fetching
- Creating Server Actions with mutations
- Optimizing page performance
- Reviewing existing component code

Cache Components enable **Partial Prerendering (PPR)** - mixing static HTML shells with dynamic streaming content for optimal performance. Cache Components also enable state preservation during navigation with React's `<Activity>` component, which can keep cached component trees mounted but hidden.

## Philosophy: Code Over Configuration

Cache Components represents a shift from **segment configuration** to **compositional code**:

| Before (Deprecated)                     | After (Cache Components)                  |
| --------------------------------------- | ----------------------------------------- |
| `export const revalidate = 3600`        | `cacheLife('hours')` inside `'use cache'` |
| `export const dynamic = 'force-static'` | Use `'use cache'` and Suspense boundaries |
| All-or-nothing static/dynamic           | Granular: static shell + cached + dynamic |

**Key Principle**: Components co-locate their caching, not just their data. Next.js provides build-time feedback to guide you toward optimal patterns.

## Core Concept

```
┌─────────────────────────────────────────────────────┐
│                   Static Shell                       │
│  (Sent immediately to browser)                       │
│                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │   Header    │  │  Cached     │  │  Suspense   │  │
│  │  (static)   │  │  Content    │  │  Fallback   │  │
│  └─────────────┘  └─────────────┘  └──────┬──────┘  │
│                                           │         │
│                                    ┌──────▼──────┐  │
│                                    │  Dynamic    │  │
│                                    │  (streams)  │  │
│                                    └─────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Mental Model: The Caching Decision Steps

When writing a React Server Component, walk through these steps in order:

1. **Does the component fetch data or perform I/O?**
   - No → pure component, nothing to decide.
   - Yes → continue.

2. **Does it depend on request context** (`cookies()`, `headers()`, `searchParams`)?
   - No → continue to step 3.
   - Yes → continue to step 4.

3. **(No request context) Is the data the same across users?**
   - Yes → add `'use cache'` with `cacheTag()` and `cacheLife()`.
   - No → wrap rendering in `<Suspense>` so the dynamic part streams at request time.

4. **(Has request context) Can you extract the runtime data as function arguments?**
   - Yes → read `cookies()`/`headers()` outside the cached scope, pass values
     into a `'use cache'` function, and wrap the dynamic caller in `<Suspense>`.
   - No (compliance prevents cross-request sharing) → use `'use cache: private'`
     as a last resort, still wrapped in `<Suspense>`.

**Key insight**: `'use cache'` is for data that is the _same across users_. User-specific
data stays dynamic and streams through `<Suspense>`. Reach for `'use cache: private'` only
when you cannot refactor runtime data into arguments.

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

## Server Actions vs Data Fetching (Critical Rule)

**Server Actions are for MUTATIONS ONLY** - never for data fetching:

| Purpose         | Use                              | Example Functions                        |
| --------------- | -------------------------------- | ---------------------------------------- |
| **Data fetch**  | Server Component / `'use cache'` | `getProducts()`, `getUser(id)`           |
| **Mutation**    | Server Action (`'use server'`)   | `createProduct()`, `updateUser()`, `deletePost()` |

### ❌ WRONG: Server Action for Data Fetching

```tsx
"use server"
export async function getProducts() {
  return await db.products.findMany() // NO! This is not a mutation
}

"use server"
export async function getTheme() {
  return (await cookies()).get("theme")?.value // NO! Just reading data
}
```

### ✅ CORRECT: Data Function + Server Component

```tsx
// data/products.ts - Cached data function
export async function getProducts() {
  "use cache"
  cacheTag("products")
  cacheLife("hours")
  return await db.products.findMany()
}

// page.tsx - Server Component reads data directly
import { cookies } from "next/headers"

export default async function Page() {
  const products = await getProducts()
  const theme = (await cookies()).get("theme")?.value ?? "light"
  return <ProductList products={products} theme={theme} />
}
```

### ✅ CORRECT: Server Action for Mutation

```tsx
"use server"
import { updateTag } from "next/cache"

export async function createProduct(formData: FormData) {
  await db.products.create({ data: formData })
  updateTag("products") // Invalidate cache after mutation
}
```

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

For **read-your-own-writes** semantics:

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

## Cache Key = Arguments

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

**Solution**: Extract runtime data outside cache boundary (see "Handling Runtime Data" above).

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
7. **Use `'use cache: private'` as last resort** - Only when runtime data cannot be extracted as params AND compliance requires no cross-request sharing

## Review Checklist

When reviewing code in Cache Components projects, flag these issues:

- [ ] Data fetching without `'use cache'` where caching would benefit
- [ ] Missing `cacheTag()` calls (makes invalidation impossible)
- [ ] Missing `cacheLife()` (relies on defaults which may not be appropriate)
- [ ] Server Actions without `updateTag()`/`revalidateTag()` after mutations
- [ ] `cookies()`/`headers()` called inside `'use cache'` scope
- [ ] Dynamic components without `<Suspense>` boundaries
- [ ] **DEPRECATED**: `export const revalidate` - replace with `cacheLife()` in `'use cache'`
- [ ] **DEPRECATED**: `export const dynamic` - replace with Suspense + cache boundaries
- [ ] Empty `generateStaticParams()` return - must provide at least one param
- [ ] Single-argument `revalidateTag('tag')` - use two-argument form with profile or `{ expire }`
