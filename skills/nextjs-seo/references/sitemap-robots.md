# Sitemap & Robots.txt in Next.js

## Contents

- [Sitemap Configuration](#sitemap-configuration) — basic, dynamic, image, video, multiple, localized sitemaps
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
    {
      url: 'https://your-site.com',
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 1,
    },
    {
      url: 'https://your-site.com/about',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.8,
    },
  ];
}
```

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
    lastModified: post.updatedAt,
    changeFrequency: 'weekly' as const,
    priority: 0.7,
  }));

  return [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    ...postUrls,
  ];
}
```

### Image Sitemap

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = 'https://your-site.com';

  return [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 1,
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
      lastModified: new Date(),
      videos: [
        {
          title: 'Video Title',
          thumbnail_loc: 'https://your-site.com/thumbnail.jpg',
          description: 'Video description',
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

### Localized Sitemap

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: 'https://your-site.com',
      lastModified: new Date(),
      alternates: {
        languages: {
          en: 'https://your-site.com/en',
          fi: 'https://your-site.com/fi',
          sv: 'https://your-site.com/sv',
        },
      },
    },
  ];
}
```

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
        disallow: '/admin/',
        crawlDelay: 2, // optional; Googlebot ignores crawl-delay, Bing/Yandex honor it
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
> AI crawler control (training vs search/citation bots, the full 2026 user-agent
> list, and a recommended pattern) lives in [ai-search.md](ai-search.md).

### Environment-Based Robots

```typescript
// app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 'https://your-site.com';

  // Block indexing on non-production
  if (process.env.NODE_ENV !== 'production') {
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
| Max file size | 50 MB |
| Update frequency | Match actual content changes |
| Priority values | 0.0 to 1.0 (homepage = 1.0) |
| Include only | Canonical, 200-status pages |

## Robots.txt Best Practices

1. **Don't block CSS/JS** - Google needs them for rendering
2. **Don't block sitemap** - Never disallow `/sitemap.xml`
3. **Use specific paths** - `/admin/` instead of broad blocks
4. **Test before deploy** - Use the Search Console robots.txt report (Settings → robots.txt) and the URL Inspection tool

### `MetadataRoute.Robots` fields

Per-rule fields: `userAgent`, `allow`, `disallow`, `crawlDelay?: number`.
Top-level fields: `sitemap`, `host`.

- `crawlDelay?: number` — seconds between requests. **Googlebot ignores
  crawl-delay; Bing/Yandex honor it.**
- `host` — non-standard, ignored by Google (see `host` caveat above).
