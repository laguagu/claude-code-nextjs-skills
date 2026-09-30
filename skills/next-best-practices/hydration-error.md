# Hydration diagnosis

Compare the initial server HTML and client render. Inspect the overlay/console
and the actual DOM; a recovered subtree can look usable while still reporting
a mismatch.

Common causes are browser storage during initial render, differing locale/time,
unstable random values, invalid nesting, and scripts/extensions mutating HTML.
`usePathname` on a prerendered page reached through a rewrite or Proxy returns
the rewritten path on the client and can mismatch.
Resolve the specific mismatch through stable server/client data or a deliberate
client-only display boundary.

Do not make the whole route client-only or suppress warnings as a generic
repair. A mount gate can be appropriate for browser-derived state, but affects
initial content/layout and needs checking.

For theme/locale flashes use `02-guides/preventing-flash-before-hydration.md`;
the error page is web-only
(`https://nextjs.org/docs/messages/react-hydration-error`). Verify both direct
production load and in-app navigation.
