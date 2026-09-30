# Metadata contracts

Use the installed Next.js docs and
[Metadata API](https://nextjs.org/docs/app/api-reference/functions/generate-metadata)
for signatures. Metadata exports run in Server Components; choose
`metadata` or `generateMetadata` in the same route segment, not both.
Export `viewport` / `generateViewport` for viewport-related fields;
`themeColor`, `colorScheme` or `viewport` inside `metadata` emit no tag, only
a build warning.
Google ignores the `keywords` meta tag; do not tune it for Google visibility.
See [supported meta tags](https://developers.google.com/search/docs/crawling-indexing/special-tags).

## URL resolution and inheritance

Set `metadataBase` to the intended public origin when using relative metadata
URLs. It applies to canonical/language alternates as well as social images.
An absolute field URL ignores `metadataBase`. An unset child canonical inherits
the parent's, so a root homepage canonical needs deliberate per-page overrides.
Missing-base behavior can differ between versions, fields and hosts; current
docs require a base for relative URL-based fields. Inspect emitted production
URLs rather than treating a development fallback or warning as the contract.

Metadata merges shallowly from root to leaf. Replacing a nested object such as
`openGraph` can discard inherited fields; explicitly carry forward needed
values or use a shared helper. File-based metadata can override config-based
metadata. Verify title templates, canonical queries and per-route image
selection in the served response.

In localized pages, provide absolute reciprocal hreflang URLs, including the
page itself. Preserve the distinction between language versions and unrelated
regional pages; avoid generating alternates for nonexistent routes.

## Async and cached metadata

Follow the installed async contracts for `params`, `searchParams` and generated
metadata IDs. Do not copy v15/16 examples into an older application without
checking types.

Metadata can be static, cached or request-dependent. With Cache Components,
request-dependent metadata and prerendered page content must meet that mode's
requirements; don't force every page into `use cache`. A cached
`generateMetadata` return must be serializable under the documented contract:
use URL strings rather than `URL` instances where required.

Next.js can stream metadata to capable clients and block for HTML-limited
bots. Check the installed `htmlLimitedBots` behavior and the complete response
for relevant agents before diagnosing “missing head tags”. The streamed tags
can appear in `<body>`; the default HTML-limited list includes Twitterbot,
Bingbot and Slackbot. Configuring `htmlLimitedBots` replaces that list rather
than extending it. Do not broaden overrides without evidence.

## Social images, icons and manifest

Use [metadata file conventions](https://nextjs.org/docs/app/api-reference/file-conventions/metadata)
when they fit. Static and generated OG/Twitter images, favicon/icon/apple-icon
files and manifests have different formats and limits; read the exact
convention before adding an export or file.

For generated images, follow
[ImageResponse](https://nextjs.org/docs/app/api-reference/functions/image-response)
rendering, font and bundle limitations: Satori supports flexbox but not
`display: grid`, the bundle (JSX, fonts, images) is capped at 500 KB, and
fonts must be ttf/otf/woff. Static `opengraph-image` files over 8 MB and
`twitter-image` files over 5 MB fail the build. Test the actual generated URL
and image, including fonts and long titles.

A web manifest is useful for an installable web app; it is not a generic SEO
requirement. Avoid duplicating equivalent icon/social-image definitions merely
to increase metadata volume.
