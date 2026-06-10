# Next.js SEO Audit Checklist

## Contents

Critical | Important | Nice to Have | Audit Tools | Red Flags

## Critical (Must Have)

### Technical Foundation

- [ ] `metadataBase` set in root layout
- [ ] Unique `<title>` on every page (50-60 chars)
- [ ] Unique `meta description` on every page (150-160 chars)
- [ ] `robots.txt` exists and allows crawling
- [ ] `sitemap.xml` exists and is valid
- [ ] Sitemap submitted to Google Search Console
- [ ] No `noindex` on pages you want indexed
- [ ] Canonical URLs set for all pages
- [ ] `viewport` exported separately from `metadata`
- [ ] `favicon.ico` (or `app/icon`) present — appears in Google SERPs and browser tabs
- [ ] `app/manifest.ts` present (name, short_name, theme_color, icons) — PWA completeness

### Rendering

- [ ] SEO pages use SSG, SSR, or `"use cache"` Cache Components (not CSR)
- [ ] Content visible without JavaScript (test with JS disabled)
- [ ] No client-side only content for SEO-critical text

### Core Web Vitals

- [ ] LCP (Largest Contentful Paint) < 2.5s
- [ ] INP (Interaction to Next Paint) < 200ms
- [ ] INP optimized (INP replaced FID in March 2024)
- [ ] CLS (Cumulative Layout Shift) < 0.1
- [ ] CWV checked on FIELD data (PageSpeed Insights / Search Console CrUX, 75th percentile) — not just Lighthouse (Lighthouse can't measure INP)
- [ ] Mobile parity — same content/metadata/structured-data on mobile (mobile-first indexing complete since July 2024)

## Important (Should Have)

### Structured Data

- [ ] WebSite schema on homepage
- [ ] Organization schema
- [ ] Relevant page-specific schemas (Article, Product) for rich results
- [ ] FAQPage = AI-search/LLM signal only (rich results removed 2026-05-07)
- [ ] JSON-LD matches visible content
- [ ] Validated with Rich Results Test

### Open Graph & Social

- [ ] Open Graph title and description
- [ ] OG image (1200x630 recommended)
- [ ] OG image set via `opengraph-image` file convention or `ImageResponse` (not just a hardcoded URL)
- [ ] Twitter Card configured
- [ ] Images tested with Facebook Debugger

### Links & Navigation

- [ ] Internal links use `<Link>` component
- [ ] No broken internal links
- [ ] Logical URL structure
- [ ] Breadcrumbs implemented (if applicable)

### Images

- [ ] All images have `alt` text
- [ ] Images use `next/image` component
- [ ] Images in sitemap
- [ ] Appropriate image sizes (no oversized images)

## Nice to Have (Optimization)

### Performance

- [ ] JavaScript bundle optimized
- [ ] Fonts use `next/font`
- [ ] Critical CSS inlined
- [ ] Third-party scripts deferred

### International (if applicable)

- [ ] `hreflang` tags for language versions
- [ ] Localized sitemaps
- [ ] Language-specific metadata

### Advanced

- [ ] Video sitemap (if video content)
- [ ] News sitemap (if news site)
- [ ] App links configured (if mobile app)

## Audit Tools

| Tool | Purpose | URL |
|------|---------|-----|
| Google Search Console | Indexing, errors | search.google.com/search-console |
| PageSpeed Insights | Core Web Vitals | pagespeed.web.dev |
| Rich Results Test | Structured data | search.google.com/test/rich-results |
| Lighthouse | Overall audit | Chrome DevTools |
| Chrome DevTools device emulation | Mobile usability | Chrome DevTools (Google's Mobile-Friendly Test was retired Dec 2023) |
| Ahrefs/Semrush | Backlinks, rankings | ahrefs.com / semrush.com |

## Quick Commands

```bash
# Check robots.txt
curl https://your-site.com/robots.txt

# Check sitemap
curl https://your-site.com/sitemap.xml

# Check if indexed
# Search in Google: site:your-site.com

# Test mobile rendering
# Use Chrome DevTools device emulation
```

## Red Flags to Watch

1. **"Discovered - currently not indexed"** in GSC
2. **Duplicate title tags** across pages
3. **Missing canonical URLs**
4. **Blocked resources in robots.txt**
5. **Slow LCP (> 4s)**
6. **High CLS (> 0.25)**
7. **No structured data**
8. **Missing alt text on images**
