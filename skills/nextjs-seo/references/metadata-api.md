# Next.js Metadata API

Complete guide for implementing SEO metadata in Next.js App Router.

## Contents

- Static vs Dynamic Metadata (`generateMetadata` full signature, `parent`, memoization)
- Complete Metadata Object (incl. `facebook`, `pinterest`, `appleWebApp`, `other`)
- Viewport Configuration
- Metadata Merging (shallow-merge gotcha)
- File-based metadata & priority
- OG / Twitter images: file conventions + `ImageResponse` + `generateImageMetadata`
- Web App Manifest & icon file conventions
- generateMetadata with Cache Components
- Open Graph image sizes / Twitter card types
- Streaming Metadata
- Best Practices

## Static vs Dynamic Metadata

### Static Metadata (metadata object)

Use when metadata is known at build time:

```typescript
// app/layout.tsx or app/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Page Title',
  description: 'Page description',
};
```

### Dynamic Metadata (generateMetadata)

Use when metadata depends on route params or external data:

```typescript
// app/products/[id]/page.tsx
import type { Metadata, ResolvingMetadata } from 'next';

type Props = {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>; // page.js only
};

export async function generateMetadata(
  { params }: Props,
  parent: ResolvingMetadata, // optional 2nd arg: read/extend parent metadata
): Promise<Metadata> {
  const { id } = await params; // params & searchParams are Promises in current Next.js
  const product = await getProduct(id);

  // Extend rather than replace parent OG images:
  const previousImages = (await parent).openGraph?.images || [];

  return {
    title: product.name,
    description: product.description,
    openGraph: {
      images: [product.image, ...previousImages],
    },
  };
}
```

**Notes:**
- `searchParams` is only available in `page.js` segments (not `layout.js`).
- `redirect()` and `notFound()` can be called inside `generateMetadata` (useful when a fetched entity doesn't exist).
- v16 typed helpers: type the first arg with `PageProps<'/products/[id]'>` or `LayoutProps<'/...'>` instead of a hand-rolled `Props` type.
- **Avoid duplicate fetches:** `fetch()` is auto-memoized between `generateMetadata` and the page. For non-`fetch` data (DB/ORM), wrap the loader in React's `cache()` so it runs once.

## Complete Metadata Object

```typescript
import type { Metadata } from 'next';

export const metadata: Metadata = {
  // Base URL for relative paths
  metadataBase: new URL('https://your-site.com'),

  // Title configuration
  title: {
    default: 'Default Title',        // Used when no page title
    template: '%s | Site Name',      // Template for child pages
    absolute: 'Override All',        // Ignores template
  },

  // Description (150-160 characters recommended)
  description: 'Compelling meta description with target keywords',

  // Keywords (less important now, but still used)
  keywords: ['keyword1', 'keyword2', 'long-tail keyword'],

  // Author information
  authors: [{ name: 'Author Name', url: 'https://author.com' }],
  creator: 'Creator Name',
  publisher: 'Publisher Name',

  // Robots directives
  robots: {
    index: true,
    follow: true,
    nocache: false,
    googleBot: {
      index: true,
      follow: true,
      noimageindex: false,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },

  // Canonical and alternates
  alternates: {
    canonical: '/',
    languages: {
      'en-US': '/en-US',
      'fi-FI': '/fi-FI',
    },
    media: { 'only screen and (max-width: 600px)': 'https://m.your-site.com' },
    types: { 'application/rss+xml': 'https://your-site.com/rss' }, // advertise feeds
  },

  // Open Graph (Facebook, LinkedIn)
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://your-site.com',
    siteName: 'Site Name',
    title: 'Open Graph Title',
    description: 'Open Graph description',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Image alt text',
        type: 'image/png',
      },
    ],
  },

  // Twitter Cards
  twitter: {
    card: 'summary_large_image',  // or 'summary' for square images
    site: '@username',
    creator: '@creator',
    title: 'Twitter Title',
    description: 'Twitter description',
    images: ['/twitter-image.png'],
  },

  // Icons
  icons: {
    icon: '/favicon.ico',
    shortcut: '/favicon-16x16.png',
    apple: '/apple-touch-icon.png',
  },

  // Verification tags
  verification: {
    google: 'google-verification-code',
    yandex: 'yandex-verification-code',
  },

  // App links
  appLinks: {
    ios: {
      url: 'https://app.example.com/ios',
      app_store_id: 'app_store_id',
    },
    android: {
      package: 'com.example.app',
      app_name: 'App Name',
    },
  },

  // Format detection (disable auto-linking)
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },

  // Category
  category: 'technology',

  // PWA manifest link (or use app/manifest.ts — see below)
  manifest: '/manifest.webmanifest',

  // Social platform extras
  facebook: { appId: '1234567890' },     // Facebook Social Plugins
  pinterest: { richPin: true },          // Pinterest Rich Pins
  appleWebApp: { capable: true, title: 'Site', statusBarStyle: 'default' },

  // Escape hatch for custom / newly-released meta tags not yet typed
  other: { 'custom-tag': 'value' },
};
```

## Viewport Configuration

**Important:** viewport must be a separate export, not a field in `metadata`:

```typescript
import type { Viewport } from 'next';

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  viewportFit: 'cover',
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0a0a0a' },
  ],
  colorScheme: 'light dark',
};
```

## Metadata Merging

Metadata merges from root to leaf. Child metadata overrides parent:

```
app/layout.tsx (base metadata)
  └── app/blog/layout.tsx (adds/overrides)
        └── app/blog/[slug]/page.tsx (final metadata)
```

**Shallow-merge gotcha:** merging is **shallow**. Redefining a nested object like `openGraph` or `robots` in a child segment **replaces the entire parent object** — sibling keys are lost. Setting only `openGraph.title` in a child drops the parent's `openGraph.description`/`images`. Fix by exporting shared nested fields and spreading them:

```typescript
// app/shared-metadata.ts
export const sharedOpenGraph = { images: ['/og-image.png'], siteName: 'Site Name' };

// child segment
export const metadata = {
  openGraph: { ...sharedOpenGraph, title: 'Child title' },
};
```

## File-based Metadata & Priority

File conventions (`favicon.ico`, `icon.*`, `apple-icon.*`, `opengraph-image.*`, `twitter-image.*`, `manifest.*`, `sitemap.*`, `robots.*`) **take priority over and override** the `metadata` object / `generateMetadata`. Next.js recommends file conventions for icons and OG images over hand-syncing the `icons`/`openGraph.images` config — and avoid using both for the same asset to prevent duplicate `<head>` tags.

## OG / Twitter Images (file conventions + ImageResponse)

Three approaches (SKILL.md has the quick version; details here):

**1. External URL** — set `openGraph.images` / `twitter.images` in metadata (shown above). Use for externally hosted images.

**2. Static file convention (recommended default):** place `opengraph-image.(jpg|jpeg|png|gif)` / `twitter-image.*` in a route segment. Next.js emits `og:image`/`twitter:image` + `:type/:width/:height`. A deeper segment's image overrides one above. Alt text via a sibling `opengraph-image.alt.txt` (→ `og:image:alt`). **Build fails** if a static file exceeds 8 MB (OG) / 5 MB (Twitter).

**3. Code-generated with `ImageResponse`:**

```tsx
// app/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from 'next/og';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

export const alt = 'Post preview';            // → og:image:alt
export const size = { width: 1200, height: 630 }; // → og:image:width/height
export const contentType = 'image/png';       // → og:image:type

export default async function Image({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;              // params is a Promise in v16
  const post = await getPost(slug);
  const font = await readFile(join(process.cwd(), 'assets/Inter-SemiBold.ttf'));

  return new ImageResponse(
    (
      <div style={{ display: 'flex', width: '100%', height: '100%', fontSize: 64 }}>
        {post.title}
      </div>
    ),
    { ...size, fonts: [{ name: 'Inter', data: font, style: 'normal', weight: 600 }] },
  );
}
```

- Default export must return one of `Blob | ArrayBuffer | TypedArray | DataView | ReadableStream | Response` — `ImageResponse` satisfies this.
- **Satori rendering:** flexbox + a subset of CSS only; `display: grid` is unsupported. Load local images via `readFile` (base64 data URI) under the Node.js runtime.
- **Caching:** these are special Route Handlers, **statically optimized** (built once, cached) unless they read request-time APIs or uncached data; they accept the same route segment config as pages.
- **Multiple images per route:** export `generateImageMetadata()` returning an array of `{ id (required), alt?, size?, contentType? }`; the default `Image({ id, params })` receives both as Promises (v16).

## Web App Manifest & Icon File Conventions

**Manifest:** `app/manifest.ts` returning `MetadataRoute.Manifest` (see SKILL.md for the full example) — or a static `app/manifest.(json|webmanifest)`.

**Icons (prefer over the metadata `icons` field):**
- `favicon.ico` — root `app/` only; appears in browser tabs **and Google SERPs**.
- `app/icon.(ico|jpg|jpeg|png|svg)` and `app/apple-icon.(jpg|jpeg|png)` — auto-emit `<link rel="icon">` / `apple-touch-icon` with correct `type`/`sizes`.
- Code-generated: `app/icon.tsx` / `app/apple-icon.tsx` with `ImageResponse` (export `size`, `contentType`). Note: `favicon.ico` cannot be code-generated — use `icon.*` or a static `.ico`.
- Multiple icons via numeric suffixes (`icon1.png`, `icon2.png`); `.svg` icons get `sizes="any"`.

## generateMetadata with Cache Components

When `cacheComponents` is enabled, a `generateMetadata` that reads runtime data (cookies/headers/searchParams or uncached fetches) while the rest of the page is prerenderable raises an error requiring an explicit choice:

- **External (non-runtime) data:** add `"use cache"` inside `generateMetadata` (with `cacheTag` for invalidation).
- **Genuine runtime data:** signal intent with a `DynamicMarker` component (`await connection()`) inside a `<Suspense>` boundary so the page can still prerender a static shell.

## Open Graph Image Sizes

| Platform | Recommended Size |
|----------|------------------|
| Facebook | 1200 x 630 px |
| Twitter (large) | 1200 x 628 px |
| Twitter (summary) | 512 x 512 px |
| LinkedIn | 1200 x 627 px |

## Twitter Card Types

| Card Type | Image Size | Use Case |
|-----------|------------|----------|
| `summary` | 1:1 (min 144x144) | Square logos, icons |
| `summary_large_image` | 2:1 (min 300x157) | Articles, products |
| `player` | Video embed | Video content |
| `app` | App store link | Mobile apps |

## Streaming Metadata

For **dynamically rendered** pages, `generateMetadata` resolves as part of rendering, and the resulting tags are **appended to the `<body>`** once it resolves — without blocking the initial UI. This improves TTFB/LCP. (Prerendered/static pages resolve metadata at build time and put it in `<head>` normally — no streaming.)

- **JS-capable bots (Googlebot):** read the streamed tags after executing JS and inspecting the full DOM.
- **HTML-limited bots:** metadata keeps blocking and is placed in `<head>`. Next.js detects these by User-Agent; the built-in list includes `Twitterbot`, `Slackbot`, `Bingbot`, `facebookexternalhit`, and more.

`htmlLimitedBots` **overrides** (replaces) the entire built-in list — it does NOT append to it:

```typescript
// next.config.ts
import type { NextConfig } from 'next';

const config: NextConfig = {
  // Fully DISABLE streaming (all bots get blocking metadata):
  htmlLimitedBots: /.*/,

  // ⚠️ A narrow regex like /facebookexternalhit|linkedinbot/ is DANGEROUS:
  // it REPLACES the default list, so Bingbot/Twitterbot/Slackbot would lose
  // their blocking metadata and get broken previews. Only override if you
  // fully understand you're replacing the whole list.
};

export default config;
```

Streaming metadata is an advanced feature — **the default is correct for almost all cases**, so usually you should not set `htmlLimitedBots` at all.

## Best Practices

1. **Always set metadataBase** - Required for relative URLs. URL composition: a missing `metadataBase` + a relative URL = **build error**; an absolute URL in any field **ignores** `metadataBase`. OG/Twitter image URLs must resolve to absolute URLs.
2. **Use title templates** - Consistent branding across pages
3. **Write unique descriptions** - Each page needs unique description
4. **Include canonical URLs** - Prevent duplicate content issues
5. **Test with validators** - Use the Facebook Sharing Debugger; for X, preview in the post composer or use a third-party OG preview tool (e.g. opengraph.xyz)
6. **Don't mix static and dynamic** - Use either `metadata` object or `generateMetadata` in the **same route segment** (a layout can use static metadata while its child page uses `generateMetadata`)
7. **`themeColor`/`colorScheme`/`viewport` are deprecated inside `metadata`** - use the separate `export const viewport` (see above)
