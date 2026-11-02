# SEO diagnosis

Start with an affected production URL and the exact observation. Compare the
complete served response, browser behavior and Search Console evidence;
these describe different layers.

## Indexing and crawl status

“Discovered – currently not indexed” says Google found the URL but has not
crawled it yet, typically because the crawl was rescheduled to avoid overloading
the site. “Crawled – currently not indexed” says a crawl did not result in
indexing. Neither status identifies a single cause or establishes a
content-length problem.

Use URL Inspection and the relevant indexing report to check fetch success,
crawl permission, noindex, declared and Google-selected canonicals. Inspect
redirects, status codes, duplicate intent and whether the page has a distinct
useful purpose. Check server/firewall logs when access is uncertain.

Change robots rules only after confirming the route should be public, and
preserve unrelated restrictions. A robots block can stop discovery of a
noindex directive. Indexing requests are optional follow-up after meaningful
fixes; repeated submissions do not guarantee indexing.

## Content missing from the served HTML

The browser hides this fault, because hydration fills the section in. Fetch the
production URL without JavaScript and search the response for a visible phrase
and a data value from each important section. Count fallback skeletons too.

With Cache Components (Next.js 16), check two causes:

- **The value is in the RSC payload (`self.__next_f`) but not in the markup.**
  The server had the data and the prerender left the Client Component out.
  Reading the clock or randomness during its render (`Date.now()`, `new Date()`,
  `Math.random()`, `crypto.randomUUID()`) stops the prerender at that point, and
  the nearest Suspense fallback is what the HTML holds. Libraries do this too:
  TanStack Query v5 reads `Date.now()` in `useQuery` for a numeric `staleTime`,
  and `dehydrate()` reads it as well. A `<Suspense>` boundary silences the
  build's prerender error by deferring the content, so the error going away does
  not mean the content is in the HTML. Keep the read out of server render, for
  example `staleTime: isServer ? "static" : ms` with seeded `initialData` (tested
  on Next.js 16.3 with TanStack Query 5.103), or move it to an effect.
- **The value is in neither.** Check the section's `cacheLife`: `revalidate: 0`,
  `expire` under 5 minutes or `stale` under 30 seconds exclude it from
  prerenders, and it resolves at request time. `stale` under 5 minutes also keeps
  it out of the App Shell. For content a crawler must read, keep `stale` and
  `expire` at 5 minutes or more and refresh live values on the client.

## Missing or wrong metadata

Compare source and the complete production response for the installed
metadata-streaming mode and relevant bot. Check inheritance, file precedence,
relative URL resolution and the correct deployment origin.
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

Test both a direct production load and client navigation: a partially
prerendered route (for example one reading `searchParams`) can serve correct
SEO HTML yet leave its Suspense content unhydrated on a direct load while
working after client navigation. An inactive browser tab can also delay streamed reveal;
rule that out before reporting a failure. Preserve a reproducible case and
investigate the installed framework/configuration.

Use [URL Inspection documentation](https://support.google.com/webmasters/answer/9012289)
for report semantics. State missing credentials, reports or verified bot logs
as limitations instead of inferring them from unrelated exports.
