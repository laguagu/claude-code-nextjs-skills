# Next.js SEO Audit Checklist

## Contents

Critical | Important | Nice to Have | Audit Tools | Red Flags

Scope the audit to the actual site. Mark optional or unavailable checks as such;
do not manufacture failures because a small site lacks every item below.

## Content and evidence first

- [ ] Headings, subtitles and introductory text add different information
- [ ] No filler, repeated keyword variants or decorative badges added for SEO
- [ ] Extra FAQ/category/team pages answer distinct needs with maintained content
- [ ] Seasons, availability, claims and dates match current data
- [ ] Performance exports are not treated as indexing, canonical or CWV reports
- [ ] Findings distinguish observed behavior from hypotheses and unavailable data

## Critical (Must Have)

### Technical Foundation

- [ ] `metadataBase` set in root layout
- [ ] Unique `<title>` on every page (~50-60 chars is a guideline, not a Google limit — titles are truncated by device width, not character count)
- [ ] Unique `meta description` on every page (~150-160 chars is a guideline — Google has no hard limit and truncates per device/query)
- [ ] Intended public pages are crawlable; robots.txt has no unintended blocks (a file is not mandatory)
- [ ] If a sitemap is useful, it contains canonical indexable URLs and accurate timestamps
- [ ] Sitemap discovery/submission checked when applicable; submission does not guarantee indexing
- [ ] No `noindex` on pages you want indexed
- [ ] Canonical signals are consistent; no inherited homepage canonical on child pages
- [ ] `viewport` exported separately from `metadata`
- [ ] `favicon.ico` (or `app/icon`) present — appears in Google SERPs and browser tabs

### Rendering

- [ ] SEO pages use SSG, SSR, or `"use cache"` Cache Components (not CSR)
- [ ] Content visible without JavaScript (test with JS disabled)
- [ ] No client-side only content for SEO-critical text
- [ ] Full production HTML and headers checked for relevant bot User-Agents; distinguish streamed metadata from missing metadata
- [ ] Direct production-build load, console/hydration errors and key interactions checked, not just navigation from the homepage
- [ ] Preview noindex/access protection verified independently of NODE_ENV

### Core Web Vitals

- [ ] LCP (Largest Contentful Paint) ≤ 2.5s
- [ ] INP (Interaction to Next Paint) ≤ 200ms (INP replaced FID in March 2024)
- [ ] CLS (Cumulative Layout Shift) ≤ 0.1
- [ ] CWV checked on FIELD data (PageSpeed Insights / Search Console CrUX, 75th percentile) — not just Lighthouse (a page-load run can't measure INP; TBT is only a lab proxy)
- [ ] Mobile parity — same content/metadata/structured-data on mobile (mobile-first indexing complete since July 2024)

## Important (Should Have)

### Structured Data

- [ ] WebSite schema on homepage
- [ ] Organization schema
- [ ] Relevant page-specific schemas (Article, Product) for rich results
- [ ] FAQPage only for an existing useful FAQ; no promised AI citation benefit (Google rich results removed 2026-05-07)
- [ ] JSON-LD matches visible content
- [ ] Eligible types validated with Rich Results Test; other schema with Schema.org Validator

### Open Graph & Social

- [ ] Open Graph title and description
- [ ] OG image (1200x630 recommended)
- [ ] OG image resolves publicly with the right MIME type; file convention, ImageResponse or metadata URL are all valid
- [ ] Twitter Card configured
- [ ] Images tested with Facebook Debugger

### Links & Navigation

- [ ] Internal links use `<Link>` component
- [ ] No broken internal links
- [ ] Logical URL structure
- [ ] Breadcrumbs implemented (if applicable)

### Images

- [ ] Informative images have useful alt text; decorative images have empty alt
- [ ] Images use `next/image` component
- [ ] Images in sitemap (only if image-search traffic matters — e.g. products, recipes, photography)
- [ ] Appropriate image sizes (no oversized images)

## Nice to Have (Optimization)

### PWA

- [ ] `app/manifest.ts` present (name, short_name, theme_color, icons) — PWA completeness, not an SEO requirement

### Performance

- [ ] JavaScript bundle optimized
- [ ] Fonts use `next/font`
- [ ] Critical CSS inlined
- [ ] Third-party scripts deferred

### International (if applicable)

- [ ] `hreflang`: every version lists itself and all others, absolute URLs, `x-default` fallback
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

# Verify indexing with Search Console URL Inspection.
# A site: search is a discovery clue, not a complete indexing report.

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
7. **Misleading structured data or unsupported rich-result claims**
8. **Missing alt text on images**
