# Hydration diagnosis

Compare the initial server HTML and client render. Inspect the overlay/console
and the actual DOM; a recovered subtree can look usable while still reporting
a mismatch.

Common causes are browser storage during initial render, differing locale/time,
unstable random values, invalid nesting, and scripts/extensions mutating HTML.
On a prerendered page reached through a rewrite or Proxy, `usePathname()` can
read a different pathname on the client and cause a mismatch. Keep that
pathname-dependent UI small and give it a stable server fallback.
Resolve the specific mismatch through stable server/client data or a deliberate
client-only display boundary.

Do not make the whole route client-only or suppress warnings as a generic
repair. For browser-derived state, a mount gate or, with React 19.3 (vendored by
the App Router from Next.js 16.4), `use(browser())` under a Suspense boundary can
be appropriate; see the installed `02-guides/single-page-applications.md`. Either
way the server HTML holds only the fallback, so keep indexable content outside it
and check initial content/layout.

Read [hydration error guidance](https://nextjs.org/docs/messages/react-hydration-error).
Verify both direct production load and in-app navigation.
