# URL hooks and rendering

| Hook | Needs a `<Suspense>` boundary |
| --- | --- |
| `useSearchParams` | Yes in a prerendered route; otherwise the tree up to the nearest boundary renders client-side and `next build` fails (`missing-suspense-with-csr-bailout`) |
| `usePathname`, `useParams`, `useSelectedLayoutSegment(s)` | Only with `cacheComponents`, when the route has params that `generateStaticParams` does not list; then the build fails without one, even in a shared layout |
| `useRouter` | No |

Development renders on demand, so a missing boundary may surface only in the
production build. Wrap the smallest component that reads the hook, not every
hook by default.

If the route is meant to render per request, `await connection()` in a Server
Component above the consumer instead; with Cache Components that call must
itself sit inside Suspense.

Read `03-api-reference/04-functions/use-search-params.md` and
`use-pathname.md`. Test direct load and client navigation after the
production build.
