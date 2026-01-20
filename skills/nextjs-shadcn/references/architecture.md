# Architecture

## Best Practices

- Avoid `useEffect` - prefer Server Components, Server Actions, or event handlers
- `"use client"` only at leaf components (smallest boundary)
- Props must be serializable (data or Server Actions, no functions/classes)
- Prefer Tailwind v4 `globals.css` theme variables over hardcoded values

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
├── (protected)/             # Auth required routes
│   ├── dashboard/
│   ├── settings/
│   ├── components/          # Route-specific components
│   └── lib/                 # Route-specific types/utils
├── (public)/                # Public routes
│   ├── login/
│   └── register/
├── actions/                 # Server Actions (global)
├── api/                     # API routes
components/                  # Shared across routes
├── ui/                      # shadcn primitives
└── shared/                  # Business components
hooks/                       # Custom React hooks
lib/                         # Shared utilities
data/                        # Database queries
ai/                          # AI logic (tools, agents, prompts)
```

### AI Directory Structure

When building AI applications, organize the `ai/` directory:

```
ai/
├── model-names.ts      # Model definitions & DEFAULT_MODEL_NAME
├── actions/            # AI-related server actions
│   ├── model.ts        # saveModelId, getModelId (cookie-based)
│   └── chat.ts         # Chat-related actions
├── utils.ts            # findSources, getLastUserMessageText, etc.
├── agents/             # Agent definitions (if using agents)
│   └── assistant.ts
└── tools/              # Tool definitions (if using tools)
```

**model-names.ts example:**

```ts
export interface Model {
  id: string
  label: string
  description: string
}

export const models: Model[] = [
  { id: "gpt-4o-mini", label: "GPT 4o mini", description: "Fast, lightweight tasks" },
  { id: "gpt-4o", label: "GPT 4o", description: "Complex, multi-step tasks" },
]

export const DEFAULT_MODEL_NAME = "gpt-4o-mini"
```

**Cookie-based model storage:**

```ts
// ai/actions/model.ts - Server Action for MUTATION only
"use server"
import { cookies } from "next/headers"

export async function saveModelId(model: string) {
  const cookieStore = await cookies()
  cookieStore.set("model-id", model)
}

// ❌ WRONG: Don't use Server Action for reading data
// export async function getModelId() { ... }

// ✅ CORRECT: Read cookies directly in Server Component
// page.tsx
import { cookies } from "next/headers"

export default async function Page() {
  const cookieStore = await cookies()
  const modelId = cookieStore.get("model-id")?.value ?? DEFAULT_MODEL_NAME
  return <Chat modelId={modelId} />
}
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

## Data Fetching Patterns

### Server Component (default)

Fetch data directly in Server Components:

```tsx
export default async function Page() {
  const data = await fetchData()
  return <Component data={data} />
}
```

### Cached Data Function

Use `'use cache'` for reusable cached queries:

```tsx
// data/products.ts
export async function getProducts() {
  "use cache"
  cacheTag("products")
  cacheLife("hours")
  return await db.products.findMany()
}
```

### Streaming to Client (React `use` hook)

Pass promises to Client Components for streaming:

```tsx
// Server Component
export default function Page() {
  const dataPromise = fetchData() // Don't await
  return (
    <Suspense fallback={<Loading />}>
      <ClientDisplay dataPromise={dataPromise} />
    </Suspense>
  )
}

// Client Component
"use client"
import { use } from "react"

export function ClientDisplay({ dataPromise }: { dataPromise: Promise<Data> }) {
  const data = use(dataPromise) // Suspends until resolved
  return <Chart data={data} />
}
```

### Explicit Request-time with connection()

Use `connection()` to explicitly defer to request time without accessing runtime APIs:

```tsx
import { connection } from "next/server"
import { Suspense } from "react"

async function UniqueContent() {
  await connection() // Defer to request time
  const uuid = crypto.randomUUID()
  const timestamp = Date.now()
  return <div>{uuid} - {timestamp}</div>
}

export default function Page() {
  return (
    <Suspense fallback={<Loading />}>
      <UniqueContent />
    </Suspense>
  )
}
```

**When to use `connection()`:**

| Scenario | Use connection()? |
|----------|-------------------|
| Need unique values per request | ✅ Yes |
| Using `Math.random()`, `Date.now()`, `crypto.randomUUID()` | ✅ Yes |
| Already using `cookies()` or `headers()` | ❌ No (not needed) |
| Data is cacheable | ❌ No (use `'use cache'`) |

## Routing

### Route Groups

Group routes without affecting URL:

```
app/
├── (protected)/         # Auth required - /dashboard, /settings
│   ├── dashboard/
│   ├── settings/
│   └── layout.tsx       # Shared chrome (sidebar, auth check)
├── (public)/            # Public - /login, /register, /about
│   ├── login/
│   ├── register/
│   └── about/
└── (marketing)/         # Marketing - /pricing, /features
    ├── pricing/
    └── features/
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

## State Management

### useTransition Pattern

Wrap non-urgent UI updates to keep interactions smooth:

```tsx
"use client"
import { useTransition } from "react"

function SubmitButton({ action }: { action: () => Promise<void> }) {
  const [isPending, startTransition] = useTransition()

  return (
    <button
      onClick={() => startTransition(() => action())}
      disabled={isPending}
    >
      {isPending ? "Saving..." : "Save"}
    </button>
  )
}
```

**Guidelines:**
- Use `isPending` for feedback (disable buttons, show spinners)
- Don't wrap controlled input state in transitions
- After `await` inside transition, wrap subsequent `setState` in another `startTransition`

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

// Refresh uncached data
import { refresh } from "next/cache"

export async function updateProfile(data: FormData) {
  await db.update(...)
  refresh() // Triggers client router refresh
}
```

### Proxy API (Next.js 16)

Replaces middleware for request interception. Place at project root (same level as `app/`):

```tsx
// proxy.ts (project root)
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"
import { cookies } from "next/headers"

export async function proxy(request: NextRequest) {
  const cookieStore = await cookies()
  const session = cookieStore.get("session")

  if (!session && request.nextUrl.pathname.startsWith("/dashboard")) {
    return NextResponse.redirect(new URL("/login", request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
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
