# Metadata contracts

Use the installed Next.js docs and
[Metadata API](https://nextjs.org/docs/app/api-reference/functions/generate-metadata)
for signatures. Metadata exports run in Server Components; choose
`metadata` or `generateMetadata` in the same route segment, not both.
Export `viewport` / `generateViewport` for viewport-related fields.

## URL resolution and inheritance

Set `metadataBase` to the intended public origin when using relative metadata
URLs. It applies to canonical/language alternates as well as social images.
An absolute field URL ignores it. Without a base, the docs describe a build
error, but the 16.3 resolver leaves canonical/hreflang URLs relative and falls
back to a Vercel URL or `localhost` for social images with only a warning.
Inspect emitted production URLs rather than trusting either.

Metadata merges shallowly from root to leaf. Replacing a nested object such as
`openGraph` can discard inherited fields; explicitly carry forward needed
values or use a shared helper. Verify title templates, canonical queries and
per-route image selection in the served response.

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

Next.js can stream metadata into `<body>` for capable clients and block for
HTML-limited bots. Check the complete response for relevant agents before
diagnosing “missing head tags”. Setting `htmlLimitedBots` replaces the default
list (Bingbot, Twitterbot, Slackbot, non-rendering Google crawlers and more)
rather than extending it; `/.*/` disables streaming. The default fits most sites.

## Social images, icons and manifest

Prefer [metadata file conventions](https://nextjs.org/docs/app/api-reference/file-conventions/metadata);
they emit the tags (type, size) and override the `metadata` object for the same asset:

| File | Static | Generated | Notes |
|---|---|---|---|
| `favicon` | `.ico` | no | Root `app/` only |
| `icon` | `.ico .jpg .jpeg .png .svg` | `.tsx` | Any segment; numeric suffixes for several |
| `apple-icon` | `.jpg .jpeg .png` | `.tsx` | |
| `opengraph-image` / `twitter-image` | `.jpg .jpeg .png .gif` | `.tsx` | Build fails above 8 MB / 5 MB; alt text in `opengraph-image.alt.txt` |

Generated files use [ImageResponse](https://nextjs.org/docs/app/api-reference/functions/image-response):
flexbox and a CSS subset only (no `display: grid`), a 500 KB bundle including
fonts and images, and `ttf`/`otf`/`woff` fonts (not `woff2`). Test the actual
generated URL and image, including fonts and long titles.

A web manifest is useful for an installable web app; it is not a generic SEO
requirement. Avoid duplicating equivalent icon/social-image definitions merely
to increase metadata volume.
