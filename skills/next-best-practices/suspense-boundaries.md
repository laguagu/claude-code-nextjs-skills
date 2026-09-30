# URL hooks and rendering

`useSearchParams` can suspend in a prerendered route; the required boundary
may be exposed only by a production build because development renders on demand.

With Cache Components, URL/param-dependent hooks can also need boundaries for
unknown dynamic params. Match `usePathname`/`useParams` behavior to the
installed version and route. Do not place Suspense around every hook by default.

If request-time rendering is intentional, use the documented request boundary
rather than a client-side workaround. Cache Components still needs a useful
fallback around request-only work.

Read the installed hook references and
[missing Suspense guidance](https://nextjs.org/docs/messages/missing-suspense-with-csr-bailout).
Test direct load and client navigation after the production build.
