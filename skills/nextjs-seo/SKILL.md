---
name: nextjs-seo
description: Next.js App Router SEO optimization and auditing. Use when implementing or fixing SEO in a Next.js app — metadata and generateMetadata, viewport/themeColor, Open Graph and og/twitter images (file conventions + ImageResponse), web app manifest, favicons/icons, sitemap.xml, robots.txt, canonical URLs, hreflang/i18n alternates, JSON-LD structured data and rich results, Core Web Vitals (LCP/INP/CLS), AI search/GEO and AI crawler rules (GPTBot, OAI-SearchBot), or diagnosing Google indexing problems (Search Console, "Discovered/Crawled - currently not indexed"). Also use to run an SEO audit checklist. Not for general Next.js feature work unrelated to SEO.
---

# Next.js SEO Optimization

## Start with evidence and useful content

Read the installed Next.js version and relevant `node_modules/next/dist/docs/`
guides before changing framework code; use current official docs when local
docs are unavailable. Use Vercel MCP documentation search for platform behavior
when available, but check retrieved examples against the installed framework.
Do not copy a legacy cache API from a search snippet into a newer app.

- Solve the reader's task first. A short useful page does not need padding.
  Give the H1, subtitle and section headings distinct jobs; do not repeat the
  same phrase in each for SEO. Keep UI copy concise, concrete and useful.
- Do not add generic introductions, keyword blocks, decorative badges, a FAQ
  or TL;DR just to make a page look optimized. Add content only when it answers
  a real question. Preserve necessary explanations and disclosures.
- Create team, location or category pages only when each offers distinct,
  maintainable value. A swapped name/logo and duplicate list is insufficient.
- Describe seasons, availability and update times from current data. Do not
  leave pre-launch copy on an active service or change timestamps for freshness.
- Separate evidence: a Search Console performance export shows queries and
  traffic, not indexing status, Google's canonical choice or CWV. Use the
  relevant report or URL Inspection; mark unavailable checks as unverified.
- Report findings and verification before predicting impact. No ranking,
  indexing, rich-result or AI-citation guarantees.

## Quick SEO Audit

Run this checklist for any Next.js project:

1. **Check robots.txt**: `curl https://your-site.com/robots.txt`
2. **Check sitemap**: `curl https://your-site.com/sitemap.xml`
3. **Check metadata**: View page source, search for `<title>` and `<meta name="description">`
4. **Check JSON-LD**: View page source, search for `application/ld+json`
5. **Check Core Web Vitals**: Use PageSpeed Insights (pagespeed.web.dev) and the Search Console CWV report for field data — Lighthouse is lab-only and can't measure INP

## Essential Files

### app/layout.tsx - Root Metadata

```typescript
import type { Metadata, Viewport } from 'next';

// Viewport must be a separate export. `themeColor`, `colorScheme` and
// `viewport` inside `metadata` are dropped: Next.js 16 emits no tag, only an
// "Unsupported metadata" build warning.
export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0a0a0a' },
  ],
};

export const metadata: Metadata = {
  metadataBase: new URL('https://your-site.com'),
  title: {
    default: 'Site Title - Main Keyword',
    template: '%s | Site Name',
  },
  // ~150-160 chars is a guideline, not a limit — Google truncates per device/query
  description: 'Compelling description with target keywords',
  // No `keywords` field: Google ignores the keywords meta tag entirely
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://your-site.com',
    siteName: 'Site Name',
    title: 'Site Title',
    description: 'Description for social sharing',
    images: [{ url: '/og-image.png', width: 1200, height: 630, alt: 'Site preview' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Site Title',
    description: 'Description for Twitter',
    images: ['/og-image.png'],
  },
  // Set alternates.canonical per page; a root '/' would be inherited by children.
  robots: {
    index: true,
    follow: true,
  },
};
```

### app/sitemap.ts - Dynamic Sitemap

```typescript
import type { MetadataRoute } from 'next';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = 'https://your-site.com';
  const posts = await getPosts(); // your CMS/DB

  return [
    {
      url: baseUrl,
      images: [`${baseUrl}/og-image.png`], // Image Sitemap entry
    },
    { url: `${baseUrl}/about` },
    ...posts.map((post) => ({
      url: `${baseUrl}/blog/${post.slug}`,
      lastModified: post.updatedAt, // real content timestamp
    })),
  ];
}
```

`lastModified` must reflect the content's actual last change (CMS `updatedAt`, file mtime, git commit date) — Google uses `lastmod` only when it's consistently accurate, and `new Date()` on every build marks everything "just changed", which teaches Google to ignore it. Skip `changeFrequency` and `priority`: Google ignores both.

### app/robots.ts - Robots Configuration

```typescript
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  const baseUrl = 'https://your-site.com';

  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/api/', '/admin/'],
        // Never disallow /_next/: crawlers need render-critical CSS/JS.
        // A named group (Googlebot, OAI-SearchBot…) ignores these rules; see mistake 11.
      },
    ],
    sitemap: `${baseUrl}/sitemap.xml`,
  };
}
```

> `host` was omitted intentionally — it's a non-standard directive Google ignores. Use canonical URLs / 301s to declare the preferred host instead. See [references/sitemap-robots.md](references/sitemap-robots.md).

### app/manifest.ts - Web App Manifest

Same `MetadataRoute` family as sitemap/robots, placed at the root of `app/`. **Not an SEO requirement** — a PWA-completeness nicety with no ranking effect; skip it unless the site is (or may become) a PWA. Full example in [references/metadata-api.md](references/metadata-api.md#web-app-manifest--icon-file-conventions).

### OG / Twitter Images

Three ways to set social images — prefer the file conventions over hand-syncing URLs in the metadata object:

1. **External URL in metadata** (the `openGraph.images` / `twitter.images` examples above) — fine for externally hosted images.
2. **Static file convention (recommended default):** drop `opengraph-image.(jpg|jpeg|png|gif)` and/or `twitter-image.*` into a route segment (`app/opengraph-image.png` for the root, `app/blog/opengraph-image.png` for `/blog`). Next.js auto-emits `og:image`/`twitter:image` + `:type/:width/:height`. A deeper, more specific image overrides one above it. Add alt text with a sibling `opengraph-image.alt.txt`. Build fails if the file exceeds 8 MB (OG) / 5 MB (Twitter).
3. **Dynamic generation with `ImageResponse`** (per-page/per-post images): an `opengraph-image.tsx` in the route segment exporting `alt`, `size`, `contentType` and a default `Image({ params })` (params is a Promise in v16) that returns `new ImageResponse(<jsx/>, { ...size })`. Renders via Satori — **flexbox only, no `display: grid`**, 500 KB bundle cap (JSX, fonts, images), fonts `ttf`/`otf`/`woff` only; statically optimized at build time unless it reads request-time data. Full example, fonts, `generateImageMetadata` and the favicon/`icon.tsx`/`apple-icon` conventions: [references/metadata-api.md](references/metadata-api.md).

## Key Principles

### Cache Components & SEO

With `cacheComponents: true`, use `"use cache"` for data/components that can be shared and whose freshness requirements permit caching. Static content needs no extra cache directive merely for SEO:

```typescript
// app/(home)/sections/hero-section.tsx
import { cacheLife, cacheTag } from "next/cache";

export async function HeroSection() {
  "use cache";
  cacheLife("hours");   // SEO content that changes a few times/day; see profiles below
  cacheTag("hero");     // Invalidate via updateTag("hero") in a Server Action

  const data = await fetchData();
  return <div>{/* SEO-visible content */}</div>;
}
```

Choose `cacheLife` from the product's freshness requirements and the installed
Next.js documentation. Do not infer a cache lifetime from the page category;
marketing and legal pages also need timely publication and invalidation.

**Key rules:**
- `"use cache"` must be the first statement in the function body (or at the top of the file for file-level caching)
- No `cookies()`/`headers()`/runtime `searchParams` inside a plain `"use cache"` scope. Keep public content separate from personalized data; do not accidentally cache private information for all users. Check the installed docs before using experimental private caching.
- Invalidate with `updateTag("hero")` inside a Server Action (read-your-writes; it throws outside one), or `revalidateTag("hero", "max")` from a Route Handler / webhook (the one-argument form is deprecated)
- Route segment exports `revalidate`, `dynamic` and `fetchCache` error with Cache Components enabled; without it, follow the installed version's cache model. Verify `next build`, the served content and publish-time invalidation.
- A database read does not by itself make a sitemap update after deployment. Configure and verify its refresh/invalidation path. Metadata can be static or runtime-dependent; inspect the route rather than assuming.

### Rendering Strategy for SEO

| Strategy | Use When | SEO Impact |
|----------|----------|------------|
| "use cache" | Shared data with a defined refresh policy | Can include content in the prerendered shell |
| SSG (Static) | Content known at build time | Content available in HTML; plan updates |
| SSR | Content needed at request time | Content available in the response; measure latency |
| CSR | Interactive or authenticated features | Avoid relying on browser-only fetching for critical public content |

These are rendering trade-offs, not ranking tiers. A Client Component can still
be server-prerendered; `"use client"` does not mean its content is absent from HTML.

### Core Web Vitals Targets

| Metric | Target | Impact |
|--------|--------|--------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | Loading speed |
| INP (Interaction to Next Paint) | ≤ 200ms | Interactivity |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | Visual stability |

- Use the 75th percentile of field measurements, segmented by device. Evaluate
  each metric separately; this does not mean the same 75% of visits pass all
  three simultaneously. Lighthouse is a lab diagnostic, not an INP field score.
- Good CWV does not guarantee ranking. Relevant content, crawlability and
  accurate metadata remain necessary; avoid invented numerical ranking weights.
- Keep mobile content, metadata and structured data equivalent to desktop.
  Verify authorship and credentials rather than generating them.

## References

- **Metadata API** — [references/metadata-api.md](references/metadata-api.md): read when writing `generateMetadata`, OG/icon files, `ImageResponse`, the manifest, or when streaming metadata / `htmlLimitedBots` is in play
- **Sitemap & Robots** — [references/sitemap-robots.md](references/sitemap-robots.md): read for `generateSitemaps`, image/video sitemaps, multi-group robots rules, static `robots.txt`/`sitemap.xml` files
- **JSON-LD Structured Data** — [references/json-ld.md](references/json-ld.md): read before adding any schema type; has the supported/deprecated rich-result list and the `@graph` pattern
- **AI Search (GEO/AEO) & AI Crawlers** — [references/ai-search.md](references/ai-search.md): read when deciding robots rules for GPTBot/OAI-SearchBot/ClaudeBot etc., or when asked about llms.txt or AI Overviews
- **SEO Audit Checklist** — [references/checklist.md](references/checklist.md): read when asked to audit a site end to end
- **Troubleshooting** — [references/troubleshooting.md](references/troubleshooting.md): read when a page is missing from Google, stuck in "Discovered/Crawled – currently not indexed", or indexes fine but never hydrates

## Common Mistakes to Avoid

1. **Mixing next-seo with Metadata API** - Use only Metadata API in App Router
2. **Missing canonical URLs** - Set a self-referencing `alternates.canonical` when duplicate/parameterized URLs are a risk; it's a hint, not a requirement — Google may pick its own canonical
3. **Using CSR for SEO pages** - Use SSG/SSR for indexable content
4. **Blocking `/_next/` in robots.txt** - Crawlers need render-critical CSS/JS; never disallow `/_next/`
5. **Missing metadataBase** - Not a build error: relative OG/Twitter image URLs fall back to the Vercel deployment URL or `http://localhost:3000` with only a warning, and relative canonical/hreflang URLs stay relative (Google requires absolute hreflang URLs)
6. **Viewport in metadata** - `themeColor`/`colorScheme`/`viewport` in `metadata` are ignored; use `export const viewport`
7. **Mixing metadata object and generateMetadata** - Use one or the other in the same route segment
8. **Duplicating icons in metadata + file conventions** - Prefer `favicon.ico`/`icon.*`/`opengraph-image.*` file conventions; they auto-emit tags and override the metadata object
9. **Blanket-blocking AI crawlers** - `GPTBot disallow: /` blocks training but leaves you in AI search; don't accidentally block search bots (OAI-SearchBot, Claude-SearchBot, PerplexityBot). See [references/ai-search.md](references/ai-search.md)
10. **Adding the `keywords` meta tag for Google** - Google ignores it entirely (no indexing or ranking effect); it's noise, not a signal
11. **Assuming named robots.txt groups inherit `*` rules** - Per RFC 9309 §2.2.1 the `*` group applies only when no group matches, and Google never merges a specific group with `*`. A `{ userAgent: 'OAI-SearchBot', allow: '/' }` group drops the wildcard's `/api/`/`/admin/` disallows — repeat them in every named group
12. **Trusting browser view for bot metadata** - Check status, headers and the complete production response for Googlebot and a relevant HTML-limited bot. Streaming may place metadata outside the initial head. A spoofed User-Agent tests response behavior, not Google's actual crawl access or indexing; use URL Inspection and verified bot logs where available.
13. **Assuming a route that indexes well also *works*** - A PPR route (`◐` in the build output) can serve perfect SEO HTML while none of its `<Suspense>` boundaries hydrate on a direct load. Load the route directly in a browser and interact with it; the observation and the check are in [references/troubleshooting.md](references/troubleshooting.md#ppr-route-serves-perfect-seo-html-but-client-components-never-hydrate).

## Quick Fixes

### Add noindex to a page

```typescript
export const metadata: Metadata = {
  robots: {
    index: false,
    follow: true,
  },
};
```

Keep the page crawlable for `noindex` to be seen. Robots disallow is not an
index-removal or access-control mechanism. Preview protection and noindex are
separate concerns; see [references/sitemap-robots.md](references/sitemap-robots.md).

### Dynamic metadata per page

```typescript
type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;            // params is a Promise in current Next.js
  const product = await getProduct(id);
  return {
    title: product.name,
    description: product.description,
  };
}
```

### Canonical for dynamic routes

```typescript
type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  return {
    alternates: {
      canonical: `/products/${slug}`,
    },
  };
}
```
