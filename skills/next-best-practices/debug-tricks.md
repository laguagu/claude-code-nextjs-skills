# Next.js diagnostics

Use the actual dev-server URL/port from the running project. When available,
the documented Next DevTools MCP forwards to the dev server's
`/_next/mcp` endpoint. Discover callable tools rather than copying raw JSON-RPC
requests or assuming a fixed tool list.

The MCP can inspect development errors, logs and page/route metadata. It does
not replace the production build, browser interaction or deployed checks.

For prerender diagnosis, use the installed CLI's targeted build/debug options.
`next build --debug-prerender` keeps server source maps and continues past the
first failure (never deploy that build). `--debug-build-paths` takes
filesystem paths/globs, not public route URLs; a targeted run does not prove
the whole app passes its required build.

Read [MCP setup](https://nextjs.org/docs/app/guides/mcp)
and the installed CLI reference.
