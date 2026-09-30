# Third-party and data scripts

Use `next/script` for third-party executable scripts when its loading lifecycle
fits. Inline executable Script content needs a stable ID. Place
`beforeInteractive` according to the router's root convention; other strategies
trade loading priority for availability.

A non-executable JSON-LD `script` is a different use case; do not force it
through a blanket third-party loader rule. Serialize untrusted content safely.

Add analytics/marketing integrations only when requested or part of the app's
existing policy. Consent, duplicate page-view tracking and SPA navigation need
the actual vendor contract, not a generic setup snippet.

Read `02-guides/scripts.md`, `03-api-reference/02-components/script.md` and
the current integration's documentation.
