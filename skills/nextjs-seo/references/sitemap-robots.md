# Sitemaps and crawl policy

Use [sitemap](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/sitemap)
and [robots](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/robots)
file conventions from the installed Next.js version. Static files can be
sufficient for a fixed site; dynamic generation needs an actual update policy.

## Sitemaps

Include absolute canonical URLs intended to be indexed. Check real statuses
and exclude redirects, unavailable pages and deliberate noindex routes.
Sitemap presence does not override crawl restrictions, canonical selection or
indexing decisions.

Use `lastModified` only for meaningful content changes from reliable data.
Do not stamp every URL with the current build/request time.

Each sitemap is limited to 50,000 URLs and 50 MB uncompressed. With
`generateSitemaps`, children are served at `<segment>/sitemap/<id>.xml`, the
plain `sitemap.xml` 404s and no index is generated; since v16 the sitemap
function receives `id` as `Promise<string>`. List the children in robots
`sitemap` (a string or array) or serve an index from a Route Handler at
another path such as `/sitemap-index.xml`.

Localized entries need absolute reciprocal language alternates including
themselves. Image/video extensions should describe actual media and meet the
consumer's requirements.

`sitemap.ts` and `robots.ts` are cached by default unless they use a
request-time API or dynamic config, so a database-backed sitemap may run only
at build time. Verify that a publication update reaches the served sitemap
using the configured cache, invalidation or rebuild path. See
[Google sitemap guidance](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap).

## Robots and previews

[Robots rules](https://developers.google.com/crawling/docs/robots-txt/robots-txt-spec)
control cooperative crawling, not access or index removal. Keep a noindex
page crawlable when the crawler must see its directive. Authentication and
deployment protection serve a different purpose.

Specific user-agent groups do not inherit the wildcard group's restrictions.
Repeat intended shared rules in named groups or avoid unnecessary groups.
Do not block render-critical assets when Google needs them. Google's parser
does not use `host` or `crawl-delay`; use redirects/canonicals for the preferred
host.

`NODE_ENV=production` also describes optimized preview builds. Use the
deployment's explicit environment policy (`VERCEL_ENV` on Vercel where
appropriate), and verify preview protection and index directives independently.

Preserve the owner's AI crawler policy; see [ai-search.md](ai-search.md).
Verify production robots status/body, affected paths and crawl diagnostics
before narrowing a rule.
