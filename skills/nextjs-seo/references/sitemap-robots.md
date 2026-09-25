# Sitemap & Robots.txt in Next.js

## Contents

- [Sitemap Configuration](#sitemap-configuration) — basic, dynamic, image, video, multiple, localized sitemaps + hreflang rules
- [Robots.txt Configuration](#robotstxt-configuration)
- [Static file conventions](#static-file-conventions)
- [Sitemap Best Practices](#sitemap-best-practices)
- [Robots.txt Best Practices](#robotstxt-best-practices)

## Sitemap Configuration

### Basic Static Sitemap

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: 'https://your-site.com' },
    { url: 'https://your-site.com/about' },
  ];
}
```

Omit `lastModified` unless you can derive a real content timestamp (CMS `updatedAt`, git commit date) — `new Date()` on every build makes `lastmod` inaccurate and Google learns to ignore it. `changeFrequency`/`priority` are ignored by Google entirely.

### Dynamic Sitemap with Database

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';
import { getAllPosts } from '@/lib/posts';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = 'https://your-site.com';
  const posts = await getAllPosts();

  const postUrls = posts.map((post) => ({
    url: `${baseUrl}/blog/${post.slug}`,
    lastModified: post.updatedAt, // real content timestamp from the CMS/DB
  }));

  return [
    { url: baseUrl },
    ...postUrls,
  ];
}
```

For a database-backed sitemap, define how it refreshes after publication. A DB
query alone may run only at build time. With Cache Components use the documented
cache/invalidation model; otherwise use the supported route revalidation policy.
Verify a content update reaches sitemap.xml without assuming a rebuild occurs.

### Image Sitemap

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = 'https://your-site.com';

  return [
    {
      url: baseUrl,
      images: [
        `${baseUrl}/og-image.png`,
        `${baseUrl}/hero-image.jpg`,
      ],
    },
  ];
}
```

### Video Sitemap

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: 'https://your-site.com/video-page',
      videos: [
        {
          title: 'Video Title',
          thumbnail_loc: 'https://your-site.com/thumbnail.jpg',
          description: 'Video description',
          // Google requires content_loc or player_loc; Next.js's own example omits it
          content_loc: 'https://your-site.com/video.mp4',
        },
      ],
    },
  ];
}
```

### Multiple Sitemaps (Large Sites)

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export async function generateSitemaps() {
  // Return array of sitemap IDs
  return [{ id: 0 }, { id: 1 }, { id: 2 }];
}

export default async function sitemap(props: {
  id: Promise<string>;
}): Promise<MetadataRoute.Sitemap> {
  const id = await props.id;
  const start = Number(id) * 50000;
  const end = start + 50000;

  const products = await getProducts(start, end);

  return products.map((product) => ({
    url: `https://your-site.com/products/${product.id}`,
    lastModified: product.updatedAt,
  }));
}
// Generates: /sitemap/0.xml, /sitemap/1.xml, /sitemap/2.xml
```

> **Note**: Sitemaps can ALSO be split by nesting `sitemap.(xml|ts|js)` under
> route segments (e.g. `app/products/sitemap.ts`). Generated multi-sitemaps are
> served at `/.../sitemap/[id].xml` relative to the file's route segment — so a
> root `app/sitemap.ts` with `generateSitemaps` yields `/sitemap/0.xml`, while
> `app/products/sitemap.ts` yields `/products/sitemap/0.xml`.
>
> Next.js does **not** generate a sitemap index for `generateSitemaps`. List each
> child in `robots.ts` (`sitemap` accepts an array) or submit them individually.

### Localized Sitemap and hreflang

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';

const languages = {
  en: 'https://your-site.com/en',
  fi: 'https://your-site.com/fi',
  'x-default': 'https://your-site.com/en',
};

export default function sitemap(): MetadataRoute.Sitemap {
  // One entry per language version; each lists every version, itself included
  return [languages.en, languages.fi].map((url) => ({
    url,
    alternates: { languages },
  }));
}
```

Google's hreflang rules apply to both `alternates.languages` in metadata and the
sitemap: each version lists itself and every other version (tags without return
links are ignored), URLs are absolute, codes are ISO 639-1 language with an
optional ISO 3166-1 alpha-2 region (`en`, `en-GB`), and `x-default` marks the
fallback. Google detects page language from content, not from hreflang or `lang`.

## Robots.txt Configuration

### Basic Robots.txt

```typescript
// app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/api/', '/admin/'],
      // Never disallow /_next/ — crawlers need render-critical CSS/JS
    },
    sitemap: 'https://your-site.com/sitemap.xml',
  };
}
```

### Multiple User Agents

```typescript
// app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/api/', '/admin/'],
      },
      {
        userAgent: 'Googlebot',
        allow: '/',
        // Named groups do NOT inherit `*` rules: RFC 9309 §2.2.1 applies the `*`
        // group only when no group matches, and Google states specific and `*`
        // groups are never combined — so repeat every disallow here
        disallow: ['/api/', '/admin/'],
        crawlDelay: 2, // optional; Google and Yandex ignore crawl-delay, Bing honors it
      },
      {
        userAgent: 'GPTBot',
        disallow: '/', // Opts out of OpenAI model TRAINING only (not citation/search)
      },
    ],
    sitemap: 'https://your-site.com/sitemap.xml',
    host: 'https://your-site.com',
  };
}
```

> **`host` caveat**: `host` is type-valid but a **non-standard directive Google
> ignores** (originally Yandex-only). Prefer canonical URLs / 301 redirects to
> declare the preferred host.

> **AI crawlers**: Blanket-blocking `GPTBot` only opts out of **training** — it
> does not block citation/search bots. Citation bots (`OAI-SearchBot`,
> `PerplexityBot`) should usually stay **allowed** so your content can be cited.
> AI crawler control (training vs search/citation bots, the current user-agent
> list, and a recommended pattern) lives in [ai-search.md](ai-search.md).

### Environment-Based Robots

`NODE_ENV` is `production` for optimized preview builds too. On Vercel use
`VERCEL_ENV` (or the project's explicit deployment policy); elsewhere use an
explicit environment setting. The following controls crawling only. For public
previews also verify a `noindex` meta tag or `X-Robots-Tag` response header and
keep access protection where required. A robots block can prevent a crawler
from seeing noindex, so do not use disallow as a removal mechanism.

```typescript
// app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 'https://your-site.com';

  // Vercel example: disallow crawling outside the production environment.
  if (process.env.VERCEL_ENV !== 'production') {
    return {
      rules: {
        userAgent: '*',
        disallow: '/',
      },
    };
  }

  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/api/', '/admin/'],
    },
    sitemap: `${baseUrl}/sitemap.xml`,
  };
}
```

## Static file conventions

Hand-authored `app/sitemap.xml` and `app/robots.txt` files are also valid
first-class conventions — good alternatives to the programmatic `.ts` forms for
small or simple sites that don't need dynamic generation.

```txt
# app/robots.txt
User-Agent: *
Allow: /
Disallow: /private/

Sitemap: https://your-site.com/sitemap.xml
```

```xml
<!-- app/sitemap.xml -->
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://your-site.com</loc>
    <lastmod>2026-01-01</lastmod>
  </url>
</urlset>
```

## Sitemap Best Practices

> **Google ignores `priority` and `changeFrequency`** — only `lastModified`
> (lastmod) is used, and only when accurate. Set lastmod from real
> content-update timestamps; don't over-invest in priority tuning.

| Guideline | Recommendation |
|-----------|----------------|
| Max URLs per sitemap | 50,000 |
| Max file size | 50 MB uncompressed |
| Update frequency | Match actual content changes |
| Priority values | Omit; Google ignores them |
| Include only | Absolute URLs of canonical, indexable, 200-status pages |

## Robots.txt Best Practices

1. **Don't block CSS/JS** - Google needs them for rendering
2. **Don't block sitemap** - Never disallow `/sitemap.xml`
3. **Use specific paths** - `/admin/` instead of broad blocks
4. **Test before deploy** - Use the Search Console robots.txt report (Settings → robots.txt) and the URL Inspection tool

### `MetadataRoute.Robots` fields

Per-rule fields: `userAgent`, `allow`, `disallow`, `crawlDelay?: number`.
Top-level fields: `sitemap`, `host`.

- `crawlDelay?: number` — seconds between requests. **Google ignores it, and
  Yandex has ignored it since 2018; Bing honors it.**
- `host` — non-standard, ignored by Google (see `host` caveat above).
