---
title: Defer Non-Critical Third-Party Libraries
impact: MEDIUM
impactDescription: loads after hydration
tags: bundle, third-party, analytics, defer
---

## Defer Non-Critical Third-Party Libraries

Analytics, logging, and error tracking don't block user interaction. Load them after hydration.

In the [Next.js App Router](https://nextjs.org/docs/app/guides/lazy-loading) (checked 2026-10-11), `ssr: false` is not supported in Server Components; put the dynamic import in a Client Component.

**Incorrect (blocks initial bundle):**

```tsx
import { Analytics } from '@vercel/analytics/react'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  )
}
```

**Correct (loads after hydration):**

```tsx
// app/analytics-client.tsx
'use client'

import dynamic from 'next/dynamic'

const Analytics = dynamic(
  () => import('@vercel/analytics/react').then(m => m.Analytics),
  { ssr: false }
)

export default function AnalyticsClient() {
  return <Analytics />
}
```

```tsx
// app/layout.tsx
import AnalyticsClient from './analytics-client'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <AnalyticsClient />
      </body>
    </html>
  )
}
```
