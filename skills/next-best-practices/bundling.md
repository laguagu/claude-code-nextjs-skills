# Package and bundle diagnosis

Trace the actual import chain and failure before changing bundler configuration.
A client boundary can still prerender; browser-only dependencies may require
a client wrapper and an explicit SSR-disabled import there.

`serverExternalPackages` changes server bundling, while `transpilePackages`
changes package transpilation. Neither is a universal ESM/CommonJS repair.
Some native packages are already automatically externalized in current releases.

Use the installed bundle analyzer and supported Turbopack/Webpack configuration.
Measure the affected route rather than marking packages incompatible from a
stale blacklist. Verify runtime dependencies in standalone output.

Keep CSS/fonts and polyfills under the project's asset strategy. Check actual
target browsers and Next.js' supported polyfills before adding another bundle.

Read [package bundling](https://nextjs.org/docs/app/guides/package-bundling)
and the installed configuration reference.
