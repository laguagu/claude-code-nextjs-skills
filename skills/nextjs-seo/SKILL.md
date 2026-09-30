---
name: nextjs-seo
description: Next.js App Router SEO implementation and audits. Use for metadata and social images, sitemap/robots, canonicals and localization, structured data, Core Web Vitals evidence, AI crawler policy or search-indexing diagnosis. Not for general Next.js feature work unrelated to SEO.
---

# Next.js SEO

Start from the page's task, production response and observed search behavior.
Read the installed Next.js version and relevant `node_modules/next/dist/docs/`
pages (bundled from 16.2); otherwise use matching official documentation.
`Metadata`, `Viewport` and `MetadataRoute` types are also in
`node_modules/next/dist/lib/metadata/types/metadata-interface.d.ts`. Keep
framework APIs, caching mode and deployment policy consistent with the project.

Useful, distinct content matters more than a longer page. Give titles,
headings and descriptions separate jobs; add a FAQ, summary, badges or extra
pages only when they help the reader. Publication dates must reflect meaningful
changes. Verify authorship, credentials and factual claims.

## Implementation and audit scope

- Verify public URLs, redirects, status codes, crawl rules, index directives
  and canonicals before adding markup. A sitemap supports discovery; it does
  not make a page indexable or guarantee indexing.
- Keep important public content available in the served HTML when practical.
  A Client Component can be server-prerendered; `use client` alone does not
  remove content from HTML.
- Use the App Router Metadata API and file conventions. Resolve relative
  metadata URLs with the correct production `metadataBase` and verify emitted
  absolute URLs. Do not rely on missing-base behavior across versions/hosts.
- Configure refresh/invalidation for data-backed pages, metadata and sitemaps.
  A database query alone does not guarantee publication updates reach them.
  Use `cache-components` when enabled; caching is a freshness decision rather
  than a required SEO directive.
- Structured data must describe real visible content and a supported consumer.
  Check current rich-result eligibility instead of adding every schema type.
- Preserve the owner's crawler policy. Training, search and user-triggered
  retrieval have different controls; robots rules are not access control.

## Read for the affected area

- [Metadata](references/metadata-api.md): inheritance, social images, icons and streaming.
- [Sitemaps/robots](references/sitemap-robots.md): discovery, localization and preview policy.
- [Structured data](references/json-ld.md): current eligibility and safe serialization.
- [AI search](references/ai-search.md): crawler purposes, policy and evidence.
- [Audit checklist](references/checklist.md): scoped production and Search Console checks.
- [Troubleshooting](references/troubleshooting.md): indexing, HTML and hydration diagnosis.

Separate evidence in the report: a performance export shows queries/traffic;
URL Inspection and indexing reports address crawl/index/canonical status;
field measurements address Core Web Vitals. Lighthouse is a lab diagnostic
and cannot establish field INP. Good field thresholds at the 75th percentile
are LCP ≤ 2.5 s, INP ≤ 200 ms and CLS ≤ 0.1.

Verify status, headers and complete production HTML, including relevant bot
responses, then open the route directly and test its interaction. A spoofed
User-Agent tests response handling, not actual verified bot access. Report
unavailable checks explicitly and avoid ranking, indexing or citation promises.
