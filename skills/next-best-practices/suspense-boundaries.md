# Suspense Boundaries

`useSearchParams` is the one client hook that causes a CSR bailout without a
Suspense boundary. Other navigation hooks (`usePathname`, `useParams`,
`useRouter`) do **not** require one.

## useSearchParams

In a prerendered (static) route, calling `useSearchParams` makes the Client
Component tree up to the nearest Suspense boundary client-side rendered. Without
a boundary, a **production build fails** with the
[Missing Suspense boundary with useSearchParams](https://nextjs.org/docs/messages/missing-suspense-with-csr-bailout)
error.

> **Dev caveat:** routes render on-demand in dev, so `useSearchParams` doesn't
> suspend and may appear to work without `Suspense` — the failure only shows up
> in a production build.

```tsx
// Bad: Entire page becomes CSR
'use client'

import { useSearchParams } from 'next/navigation'

export default function SearchBar() {
  const searchParams = useSearchParams()
  return <div>Query: {searchParams.get('q')}</div>
}
```

```tsx
// Good: Wrap in Suspense
import { Suspense } from 'react'
import SearchBar from './search-bar'

export default function Page() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <SearchBar />
    </Suspense>
  )
}
```

## Forcing dynamic rendering instead

If you intend the route to be dynamic anyway, call
[`connection()`](https://nextjs.org/docs/app/api-reference/functions/connection)
in a Server Component before rendering the hook's consumer. This opts the
subtree out of prerendering, so no Suspense boundary is needed:

```tsx
import { connection } from 'next/server'
import SearchBar from './search-bar'

export default async function Page() {
  await connection() // route is now dynamic
  return <SearchBar />
}
```

## Quick Reference

| Hook | Suspense Required |
|------|-------------------|
| `useSearchParams()` | Yes (static routes) |
| `usePathname()` | No |
| `useParams()` | No |
| `useRouter()` | No |
