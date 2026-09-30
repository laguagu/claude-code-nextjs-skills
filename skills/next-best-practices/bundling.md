# Package and bundle diagnosis

Trace the actual import chain and failure before changing bundler configuration.
A client boundary can still prerender; browser-only dependencies may require
a client wrapper and an explicit SSR-disabled import there.

`serverExternalPackages` changes server bundling, while `transpilePackages`
changes package transpilation. Neither is a universal ESM/CommonJS repair.
Some native packages are already automatically externalized.

Turbopack is the default for dev and build in 16. A `webpack` function (often
added by a plugin) fails `next build` unless `--webpack` (keep Webpack) or
`--turbopack` (ignore it) is passed; port it to top-level `turbopack` options
where possible. A browser import of `fs` is best
fixed in code; `turbopack.resolveAlias` with a `browser` stub is the fallback.

Measure the affected route: `next experimental-analyze` (16.1+, Turbopack) or
`@next/bundle-analyzer` (Webpack). Next 16 removed the `First Load JS` build
column. Verify runtime dependencies in standalone output.

Keep CSS/fonts and polyfills under the project's asset strategy. Check actual
target browsers and Next.js' supported polyfills before adding another bundle.

Read `02-guides/package-bundling.md` and
`03-api-reference/05-config/01-next-config-js/turbopack.md`.
