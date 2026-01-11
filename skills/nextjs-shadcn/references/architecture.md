# Architecture

## Component Patterns

### Server vs Client Decision Tree

```
Need state/effects/browser APIs?
├── Yes → "use client" at smallest boundary
└── No → Server Component (default)

Passing data to client?
├── Functions/classes → ❌ Not serializable
├── Plain objects/arrays → ✅ Props
└── Server logic → ✅ Server Actions
```

### Component Placement

```
app/
├── (feature)/
│   ├── components/          # Route-specific
│   │   ├── feature-card.tsx
│   │   └── feature-list.tsx
│   └── lib/                 # Route-specific types/utils
│       └── types.ts
components/                  # Shared across routes
├── ui/                      # shadcn primitives
└── shared/                  # Business components
lib/                         # Shared utilities
data/                        # Database queries
ai/                          # AI logic
```

### className Pattern

Always accept and merge `className`:

```tsx
import { cn } from "@/lib/utils"

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "default" | "outline"
}

export function Card({ className, variant = "default", ...props }: CardProps) {
  return (
    <div
      className={cn(
        "rounded-lg p-4",
        variant === "outline" && "border",
        className
      )}
      {...props}
    />
  )
}
```

## Routing

### Route Groups

Group routes without affecting URL:

```
app/
├── (marketing)/         # /about, /pricing
│   ├── about/
│   └── pricing/
├── (dashboard)/         # /dashboard, /settings
│   ├── dashboard/
│   ├── settings/
│   └── layout.tsx       # Shared dashboard chrome
└── (auth)/              # /login, /register
    ├── login/
    └── register/
```

### Layout vs Template

| Aspect | layout.tsx | template.tsx |
|--------|------------|--------------|
| State | Persists across navigation | Resets on navigation |
| Effects | Run once | Run on every navigation |
| Use when | Shared chrome (nav, footer) | Analytics, animations that reset |

**Decision tree:**
```
State/effects should reset on navigation?
├── Yes → template.tsx
└── No → layout.tsx (default)
```

### Async Params (Next.js 16)

```tsx
// Always await params and searchParams
export default async function Page({
  params,
  searchParams,
}: {
  params: Promise<{ slug: string }>
  searchParams: Promise<{ page?: string }>
}) {
  const { slug } = await params
  const { page = "1" } = await searchParams

  const data = await fetchData(slug, parseInt(page))
  return <Content data={data} />
}
```

## Suspense Strategy

### When to Use Suspense

```
Slow data fetch in Server Component?
├── Yes → Wrap in <Suspense>
└── No → Direct render

Multiple independent slow sections?
├── Yes → Separate <Suspense> boundaries
└── No → Single boundary or loading.tsx
```

### Patterns

**loading.tsx** - Entire route fallback:
```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return <DashboardSkeleton />
}
```

**Suspense** - Granular streaming:
```tsx
export default function Page() {
  return (
    <>
      <Header />  {/* Renders immediately */}
      <Suspense fallback={<StatsSkeleton />}>
        <SlowStats />  {/* Streams when ready */}
      </Suspense>
      <Suspense fallback={<ChartSkeleton />}>
        <SlowChart />  {/* Streams independently */}
      </Suspense>
    </>
  )
}
```

**Skeleton pattern** - Create a skeleton component for each loadable content:
```tsx
// components/skeletons.tsx
export function CardSkeleton() {
  return (
    <div className="animate-pulse">
      <div className="h-4 bg-muted rounded w-3/4 mb-2" />
      <div className="h-4 bg-muted rounded w-1/2" />
    </div>
  )
}

export function TableSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <div className="space-y-2">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="h-10 bg-muted rounded animate-pulse" />
      ))}
    </div>
  )
}
```

**Passing promises to client**:
```tsx
// Server Component
export default function Page() {
  const dataPromise = fetchData()  // Start fetch, don't await
  return <ClientChart dataPromise={dataPromise} />
}

// Client Component
"use client"
import { use } from "react"

export function ClientChart({ dataPromise }) {
  const data = use(dataPromise)  // Suspends until resolved
  return <Chart data={data} />
}
```

## Data Patterns

### "use cache" (Next.js 16)

Function-level caching:

```tsx
"use cache"

export async function getProducts() {
  const products = await db.query.products.findMany()
  return products
}

// With cache tags
import { cacheTag } from "next/cache"

export async function getProduct(id: string) {
  "use cache"
  cacheTag(`product-${id}`)
  return db.query.products.findFirst({ where: eq(products.id, id) })
}
```

### Server Actions

```tsx
"use server"

import { updateTag, revalidateTag } from "next/cache"
import { z } from "zod"

const schema = z.object({
  title: z.string().min(1),
  content: z.string(),
})

export async function createPost(formData: FormData) {
  const parsed = schema.parse({
    title: formData.get("title"),
    content: formData.get("content"),
  })

  await db.insert(posts).values(parsed)

  // Read-your-writes (immediate)
  updateTag("posts")

  // Or SWR-style revalidation
  // revalidateTag("posts", "max")
}
```

### Proxy API (Next.js 16)

Replaces middleware for request interception:

```tsx
// app/api/[...proxy]/proxy.ts
import { cookies } from "next/headers"
import { redirect } from "next/navigation"

export async function proxy(request: Request) {
  const cookieStore = await cookies()
  const session = cookieStore.get("session")

  if (!session) {
    redirect("/login")
  }

  // Continue to API route
  return null
}
```

### Request APIs

All request APIs are async in Next.js 16:

```tsx
import { cookies, headers, draftMode } from "next/headers"

export default async function Page() {
  const cookieStore = await cookies()
  const headersList = await headers()
  const { isEnabled } = await draftMode()
}
```

## Error Handling

Define only when custom UX needed:

```
app/
├── error.tsx           # Route-level errors
├── global-error.tsx    # Root layout errors
├── not-found.tsx       # 404 pages
└── loading.tsx         # Loading states
```

Otherwise inherit from parent segment.
