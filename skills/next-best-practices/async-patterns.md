# Async request APIs

Next.js 16 removed the synchronous fallback that 15 kept: `params`,
`searchParams`, `cookies()`, `headers()` and `draftMode()` must be awaited in
async server code, or unwrapped with React `use()` in a sync component. This
also covers `params` in route handlers, `default`, and the image/icon routes.

```tsx
export default async function Page(props: PageProps<'/blog/[slug]'>) {
  const { slug } = await props.params
}
```

`PageProps`, `LayoutProps` and `RouteContext` are global after `next typegen`,
`next dev` or `next build`.

Resolve request-dependent values at the boundary that actually needs them.
Awaiting params at a high layout level can reduce the reusable shell; with
Cache Components, keep unknown/request-only work under a useful boundary.
Do not pass unresolved request promises into a shared cache function. Client
components cannot be async.

Migration: `npx @next/codemod@canary next-async-request-api .`, then review
the actual types and runtime behavior. Source:
`02-guides/upgrading/version-16.md` (Async Request APIs).
