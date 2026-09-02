---
name: nextjs-seo
description: Next.js App Router SEO optimization and auditing. Use when implementing or fixing SEO in a Next.js app — metadata and generateMetadata, viewport/themeColor, Open Graph and og/twitter images (file conventions + ImageResponse), web app manifest, favicons/icons, sitemap.xml, robots.txt, canonical URLs, hreflang/i18n alternates, JSON-LD structured data and rich results, Core Web Vitals (LCP/INP/CLS), AI search/GEO and AI crawler rules (GPTBot, OAI-SearchBot), or diagnosing Google indexing problems (Search Console, "Discovered/Crawled - currently not indexed"). Also use to run an SEO audit checklist. Not for general Next.js feature work unrelated to SEO.
---

# Next.js SEO Optimization

Comprehensive SEO guide for Next.js App Router applications.

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

// Viewport must be a separate export — `themeColor`, `colorScheme`, and
// `viewport` inside the `metadata` object are deprecated (since v14: still
// emitted with a warning today, not guaranteed to stay).
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
  alternates: {
    canonical: '/',
  },
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
        // Do NOT disallow /_next/ — crawlers need render-critical CSS/JS
        // Do NOT add bot-specific rules (Googlebot, Bingbot) unless overriding wildcard —
        // and if you do, repeat all disallows: named groups don't inherit `*` rules
        // (RFC 9309 §2.2.1; Google never merges a specific group with `*`)
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
2. **Static file convention (recommended default):** drop `opengraph-image.(png|jpg|gif)` and/or `twitter-image.*` into a route segment (`app/opengraph-image.png` for the root, `app/blog/opengraph-image.png` for `/blog`). Next.js auto-emits `og:image`/`twitter:image` + `:type/:width/:height`. A deeper, more specific image overrides one above it. Add alt text with a sibling `opengraph-image.alt.txt`. Build fails if the file exceeds 8 MB (OG) / 5 MB (Twitter).
3. **Dynamic generation with `ImageResponse`** (per-page/per-post images): an `opengraph-image.tsx` in the route segment exporting `alt`, `size`, `contentType` and a default `Image({ params })` (params is a Promise in v16) that returns `new ImageResponse(<jsx/>, { ...size })`. Renders via Satori — **flexbox only, no `display: grid`**; statically optimized at build time unless it reads request-time data. Full example, fonts, `generateImageMetadata` and the favicon/`icon.tsx`/`apple-icon` conventions: [references/metadata-api.md](references/metadata-api.md).

## Key Principles

### Cache Components & SEO

With `cacheComponents: true` in next.config.ts (the v16 top-level flag that unifies the old `experimental.dynamicIO`/`ppr`/`useCache`), use the `"use cache"` directive for SEO-critical server components:

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

**Built-in `cacheLife` profiles** (`stale` / `revalidate` / `expire`): `seconds` (30s/1s/1m), `minutes` (5m/1m/1h), `hours` (5m/1h/1d), `days` (5m/1d/1w), `weeks` (5m/1w/30d), `max` (5m/30d/1y), and the implicit `default` (5m/15m/never). For SEO pages pick by how often content changes — `days` for blog/docs, `max` for legal/marketing. (`minutes` revalidates every 1 min — too aggressive for most SEO content.)

**Key rules:**
- `"use cache"` must be the first statement in the function body (or at the top of the file for file-level caching)
- No `cookies()`/`headers()`/`searchParams` inside a plain `"use cache"` scope — good for SEO, since indexable content should be request-agnostic. (`"use cache: private"` *does* allow them, but is never prerendered, so it never lands in the static SEO shell.)
- Invalidate with `updateTag("hero")` inside a Server Action (read-your-writes; it throws outside one), or `revalidateTag("hero", "max")` from a Route Handler / webhook (pass the profile — the one-argument form is legacy behaviour) — prefer these over `export const revalidate`
- Very short cache profiles can change what Next.js includes in the prerendered shell. Do not infer that behavior from `revalidate` alone: choose a profile from the documented freshness requirements and verify the installed Next.js version's `next build` output. Prefer `hours`/`days`/`max` for SEO-critical content unless the product genuinely needs fresher data
- Sitemaps and metadata are static by default — only add `"use cache"` (+ `cacheTag`) if they fetch CMS/dynamic data you want to invalidate on publish

### Rendering Strategy for SEO

| Strategy | Use When | SEO Impact |
|----------|----------|------------|
| "use cache" | Server components with periodic data | Best - cached HTML, fast TTFB |
| SSG (Static) | Content rarely changes | Best - pre-rendered HTML |
| SSR | Dynamic content per request | Great - server-rendered |
| CSR | Dashboards, authenticated areas | Poor - avoid for SEO pages |

### Core Web Vitals Targets

| Metric | Target | Impact |
|--------|--------|--------|
| LCP (Largest Contentful Paint) | < 2.5s | Loading speed |
| INP (Interaction to Next Paint) | < 200ms | Interactivity |
| CLS (Cumulative Layout Shift) | < 0.1 | Visual stability |

- **Measured on field data, not lab.** Google ranks on the 75th percentile of real users (Chrome UX Report, 28-day rolling window, mobile/desktop separate). A URL group passes only when ≥75% of visits hit "Good" on all three. Use PageSpeed Insights and the Search Console CWV report for the real signal — **Lighthouse is lab-only and cannot measure INP**.
- **INP replaced FID** as a Core Web Vital on 2024-03-12; FID is deprecated. INP is the most commonly failed metric — prioritize it.
- **Page experience is a tiebreaker, not a standalone ranking system** (Google de-emphasized it). Good CWV won't rescue thin content; content relevance and quality come first. Treat CWV as baseline UX hygiene.
- **Myths to ignore:** 2026 SEO blogs falsely claim "LCP was lowered to 2.0s" and invent an "Engagement Reliability" metric. Neither exists in any Google/web.dev source — the LCP and CLS thresholds are unchanged since 2021, and INP's 200 ms has been fixed since it became a Core Web Vital in 2024.

### Ranking Signals Beyond Technical SEO

Metadata + CWV alone don't drive rankings. Keep these in mind (out of scope for this skill, but pointers):

- **Helpful content** is part of core ranking (since 2024-03), evaluated continuously — not an episodic penalty.
- **E-E-A-T** (Experience, Expertise, Authoritativeness, Trust): cite real authors/credentials and first-hand experience, especially on YMYL pages.
- **Mobile-first indexing is complete** (since 2024-07): Google indexes the mobile rendering only. Ensure the mobile view has the same content, metadata, and structured data as desktop; never block mobile resources. (Mostly automatic with Next.js responsive design.)

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
5. **Missing metadataBase** - Required for relative URLs in metadata
6. **Viewport in metadata** - Must be a separate export
7. **Mixing metadata object and generateMetadata** - Use one or the other in the same route segment
8. **Duplicating icons in metadata + file conventions** - Prefer `favicon.ico`/`icon.*`/`opengraph-image.*` file conventions; they auto-emit tags and override the metadata object
9. **Blanket-blocking AI crawlers** - `GPTBot disallow: /` blocks training but leaves you in AI search; don't accidentally block citation bots (OAI-SearchBot, PerplexityBot). See [references/ai-search.md](references/ai-search.md)
10. **Adding the `keywords` meta tag for Google** - Google ignores it entirely (no indexing or ranking effect); it's noise, not a signal
11. **Assuming named robots.txt groups inherit `*` rules** - Per RFC 9309 §2.2.1 the `*` group applies only when no group matches, and Google never merges a specific group with `*`. A `{ userAgent: 'OAI-SearchBot', allow: '/' }` group drops the wildcard's `/api/`/`/admin/` disallows — repeat them in every named group
12. **Trusting browser view for bot metadata** - PPR + streaming metadata has served bots pages with no `<title>`/canonical (vercel/next.js #95406 — check its status on your version), and the browser view never shows it. Confirm production HTML with a bot User-Agent: `curl -A "Googlebot" https://your-site.com | grep -E '<title>|canonical'`
13. **Assuming a route that indexes well also *works*** - A PPR route (`◐` in the build output) can serve perfect SEO HTML while none of its `<Suspense>` boundaries hydrate on a direct load. Load the route directly in a browser and interact with it; the observation and the check are in [references/troubleshooting.md](references/troubleshooting.md#ppr-route-serves-perfect-seo-html-but-client-components-never-hydrate).

## Quick Fixes

### Add noindex to a page

```typescript
export const metadata: Metadata = {
  robots: {
    index: false,
    follow: false,
  },
};
```

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
