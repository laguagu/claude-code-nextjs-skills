# Next.js diagnostics

Use the actual dev-server URL/port from the running project (`.next/dev/lock`
records it). Next.js 16+ exposes `/_next/mcp` in the dev server; the
`next-devtools-mcp` package (configured in `.mcp.json`) discovers it and offers
errors, logs, routes and compilation status. Discover callable tools rather
than assuming a fixed list. Dev insights appear only in the overlay, terminal
and MCP; the page still returns 200.

The MCP does not replace the production build, browser interaction or deployed
checks.

For prerender failures, `next build --debug-prerender` adds server source maps
and continues past the first error (never deploy that build).
`next build --debug-build-paths="app/blog/[slug]/page.tsx"` takes file
paths/globs, not URLs; a targeted run does not prove the whole app builds.

Read `02-guides/mcp.md`, `02-guides/ai-agents.md` and
`03-api-reference/06-cli/next.md`.
