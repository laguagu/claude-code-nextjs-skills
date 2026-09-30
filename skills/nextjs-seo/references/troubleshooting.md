# SEO diagnosis

Start with an affected production URL and the exact observation. Compare the
complete served response, browser behavior and Search Console evidence;
these describe different layers.

## Indexing and crawl status

“Discovered – currently not indexed” says Google knows the URL without an
indexed crawl yet. “Crawled – currently not indexed” says a crawl did not result
in indexing. Neither status identifies a single cause or establishes a
content-length problem.

Use URL Inspection and the relevant indexing report to check fetch success,
crawl permission, noindex, declared and Google-selected canonicals. Inspect
redirects, status codes, duplicate intent and whether the page has a distinct
useful purpose. Check server/firewall logs when access is uncertain.

Change robots rules only after confirming the route should be public, and
preserve unrelated restrictions. A robots block can stop discovery of a
noindex directive. Indexing requests are optional follow-up after meaningful
fixes; repeated submissions do not guarantee indexing.

## Missing or wrong metadata

Compare source and the complete production response for the installed
metadata-streaming mode and relevant bot. Check inheritance, file precedence,
relative URL resolution and the correct deployment origin. A spoofed bot
User-Agent tests route behavior, not verified Google crawl access.
See [metadata-api.md](metadata-api.md).

## Content is stale

Trace the actual publication, cache and invalidation path for the page,
metadata and sitemap. A database read or changed source file is not proof the
deployed route refreshed. Test the real update rather than substituting a
generic cache lifetime.

## HTML is correct but interaction fails

Indexable HTML does not prove hydration. Directly open the route in a
production browser and test buttons, forms and Suspense content. Inspect
console errors, streamed RSC responses, failed assets, client/server initial
state and the deployed proxy.

A previous app exhibited correct SEO HTML with stalled PPR boundaries; that
observation is a reason to test, not a universal Next.js defect or proof of a
particular repair. Preserve a reproducible case and investigate the installed
framework/configuration.

Use [URL Inspection documentation](https://support.google.com/webmasters/answer/9012289)
for report semantics. State missing credentials, reports or verified bot logs
as limitations instead of inferring them from unrelated exports.
