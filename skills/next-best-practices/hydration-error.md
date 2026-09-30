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
repair. A mount gate can be appropriate for browser-derived state, but affects
initial content/layout and needs checking.

Read [hydration error guidance](https://nextjs.org/docs/messages/react-hydration-error).
Verify both direct production load and in-app navigation.
