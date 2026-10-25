# URL hooks and rendering

`useSearchParams` can suspend in a prerendered route; the required boundary
may be exposed only by a production build because development renders on demand.

With Cache Components, `usePathname`, `useParams` and
`useSelectedLayoutSegment(s)` also suspend in routes
whose dynamic params `generateStaticParams` does not cover, and the build
fails without a boundary. A layout sidebar reading `usePathname` for active
links therefore suspends below every such page; wrap that component, not the
layout. `useRouter` never needs one. Do not place Suspense around every hook
by default.

If request-time rendering is intentional, `await connection()` (`next/server`)
in a Server Component opts the subtree out of prerendering; with Cache
Components it must itself sit under Suspense. Prefer that to a client-side
workaround, and keep a useful fallback around request-only work.

Read the installed hook references and
[missing Suspense guidance](https://nextjs.org/docs/messages/missing-suspense-with-csr-bailout).
Test direct load and client navigation after the production build.
