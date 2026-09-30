# Scoped SEO audit

Select representative route types, languages and deployment environments.
Record production URLs and the relevant Next.js version/configuration.
Do not add every optional feature to make a checklist pass.

1. **Page usefulness:** Does each indexable page answer a distinct task with
   accurate information? Check misleading availability/dates, duplicate pages
   and repetitive UI copy.
2. **Access and discovery:** Check actual status/redirect chains, internal
   links, robots rules, sitemap entries and index directives. Verify public
   versus preview/private intent.
3. **Canonical/localization:** Inspect absolute canonical URLs, query handling
   and reciprocal hreflang where applicable. Compare Google-selected canonicals
   through URL Inspection when available.
4. **Served metadata:** Inspect title/description, social images and icons for
   the route. Check complete responses and streaming behavior for relevant
   bots. Test image URLs; missing optional tags are not automatically defects.
5. **Structured data:** Add only relevant accurate types. Check current
   eligibility, visible facts and safe serialization; validate the production
   output.
6. **Rendering and usability:** Inspect critical public content in the response,
   then directly open the route and exercise hydration/navigation. Check mobile
   equivalence, media dimensions and the changed interaction.
7. **Performance:** Use field CWV where available and lab tools for diagnosis.
   Distinguish LCP, INP and CLS evidence; lab Lighthouse is not field INP.
8. **Publication:** Change representative content and verify page, metadata
   and sitemap freshness through the real invalidation/rebuild path.
9. **Crawler policy:** Preserve intentional training/search distinctions and
   access protection. Check firewall/access logs when public crawls fail.
10. **Search evidence:** Use indexing/URL Inspection for indexing and canonical
    questions, performance for query/traffic questions, and analytics for
    referrals. A performance export cannot establish all three.

Rank findings by impact and evidence, link affected routes/files and record
checks that could not run. Separate confirmed bugs from hypotheses and
optional improvements. See [troubleshooting.md](troubleshooting.md) and
[Google Search Essentials](https://developers.google.com/search/docs/essentials).
