# Package and bundle diagnosis

Trace the actual import chain and failure before changing bundler configuration.
A client boundary can still prerender; browser-only dependencies may require
a client wrapper and an explicit SSR-disabled import there.

`serverExternalPackages` changes server bundling, while `transpilePackages`
changes package transpilation. Neither is a universal ESM/CommonJS repair.
Some native packages are already automatically externalized in current releases.

In Next.js 16, the `webpack` function that fails a default Turbopack build can
come from a plugin. Port compatible options to the top-level `turbopack` config
when migration is in scope.

Use the installed bundle analyzer and supported Turbopack/Webpack configuration.
Measure the affected route rather than marking packages incompatible from a
stale blacklist. Verify runtime dependencies in standalone output.
`next experimental-analyze` supports Turbopack from 16.1 (`next analyze` from
16.4, which keeps the old name as an alias); use `@next/bundle-analyzer` for Webpack. Next.js 16 removed the build's `First Load
JS` column, so measure the actual delivered route.

Keep CSS/fonts and polyfills under the project's asset strategy. Check actual
target browsers and Next.js' supported polyfills before adding another bundle.

Read [package bundling](https://nextjs.org/docs/app/guides/package-bundling)
and the installed configuration reference.
