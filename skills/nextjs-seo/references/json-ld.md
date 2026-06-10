# JSON-LD Structured Data in Next.js

Structured data helps search engines understand your content and enables rich results.

## Contents

- [Implementation Pattern](#implementation-pattern)
- [Common Schemas](#common-schemas) — WebSite, Organization, WebApplication, FAQPage, Product, Article, BreadcrumbList
- [Deprecated / no longer rich-result-eligible](#deprecated--no-longer-rich-result-eligible)
- [Which schema types still drive rich results (2026)](#which-schema-types-still-drive-rich-results-2026)
- [@graph multi-entity pattern](#graph-multi-entity-pattern)
- [Structured data for AI search](#structured-data-for-ai-search)
- [Usage in Next.js](#usage-in-nextjs)
- [Testing Tools](#testing-tools)
- [Best Practices](#best-practices)

## Implementation Pattern

```typescript
// components/seo/json-ld.tsx
type JsonLdProps = {
  data: Record<string, unknown>;
};

export function JsonLd({ data }: JsonLdProps) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        __html: JSON.stringify(data).replace(/</g, '\\u003c'), // XSS protection
      }}
    />
  );
}
```

## Common Schemas

### WebSite Schema

```typescript
const websiteSchema = {
  '@context': 'https://schema.org',
  '@type': 'WebSite',
  name: 'Site Name',
  url: 'https://your-site.com',
  description: 'Site description',
  inLanguage: 'en',
  publisher: {
    '@type': 'Organization',
    name: 'Organization Name',
  },
};
```

### Organization Schema

```typescript
const organizationSchema = {
  '@context': 'https://schema.org',
  '@type': 'Organization',
  name: 'Company Name',
  url: 'https://your-site.com',
  logo: {
    '@type': 'ImageObject',
    url: 'https://your-site.com/logo.png',
    width: 512,
    height: 512,
  },
  sameAs: [
    'https://twitter.com/company',
    'https://linkedin.com/company/company',
    'https://github.com/company',
  ],
  contactPoint: {
    '@type': 'ContactPoint',
    email: 'contact@company.com',
    contactType: 'customer service',
  },
  foundingDate: 'YYYY', // your real founding year
  areaServed: {
    '@type': 'Country',
    name: 'Finland',
  },
};
```

### WebApplication Schema

```typescript
const webAppSchema = {
  '@context': 'https://schema.org',
  '@type': 'WebApplication',
  name: 'App Name',
  url: 'https://your-site.com',
  description: 'App description',
  applicationCategory: 'UtilityApplication',
  operatingSystem: 'Any',
  browserRequirements: 'Requires JavaScript',
  offers: {
    '@type': 'Offer',
    price: '0',
    priceCurrency: 'EUR',
  },
  featureList: [
    'Feature 1',
    'Feature 2',
    'Feature 3',
  ],
};
```

### FAQPage Schema

> **⚠️ FAQ rich results are deprecated.** Google restricted them to authoritative gov/health sites in Aug 2023 and **fully removed them for all sites as of 2026-05-07** (Rich Results Test support drops June 2026, Search Console API August 2026). FAQPage no longer produces any rich result in Google Search. Keep this markup only as an optional AI-search / LLM-extraction signal (machine-readable Q&A) — not for SERP enhancement. Existing markup is harmless but has no visible SERP effect.

```typescript
const faqSchema = {
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  mainEntity: [
    {
      '@type': 'Question',
      name: 'What is your product?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'Our product is a tool that helps you...',
      },
    },
    {
      '@type': 'Question',
      name: 'How much does it cost?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'Our service is completely free to use.',
      },
    },
  ],
};
```

**Important:** FAQPage schema must match visible FAQ content on the page. Google rejects rich results if JSON-LD doesn't match visible content.

### Product Schema

```typescript
const productSchema = {
  '@context': 'https://schema.org',
  '@type': 'Product',
  name: 'Product Name',
  image: ['https://your-site.com/product.jpg'],
  description: 'Product description',
  sku: 'SKU123',
  brand: {
    '@type': 'Brand',
    name: 'Brand Name',
  },
  offers: {
    '@type': 'Offer',
    url: 'https://your-site.com/product',
    priceCurrency: 'EUR',
    price: '99.99',
    priceValidUntil: '2026-12-31', // use a real future date
    availability: 'https://schema.org/InStock',
    itemCondition: 'https://schema.org/NewCondition',
  },
  aggregateRating: {
    '@type': 'AggregateRating',
    ratingValue: '4.5',
    reviewCount: '89',
  },
};
```

#### Product snippet vs merchant listing experience

Google treats `Product` markup as two distinct experiences:

- **(a) Product snippet** — for editorial / non-purchase pages (reviews, roundups, comparisons). Supports review features (`aggregateRating` / `review`) and pros & cons via `positiveNotes` / `negativeNotes`. No price required.
- **(b) Merchant listing experience** — for pages where the product is purchasable. Needs `offers` with `price` + `priceCurrency` + `availability`, and benefits from `shippingDetails` and `hasMerchantReturnPolicy` for richer shopping results.

For products with variants, use `ProductGroup` with `hasVariant`, `variesBy`, and a stable `productGroupID`:

```typescript
const productGroupSchema = {
  '@context': 'https://schema.org',
  '@type': 'ProductGroup',
  name: 'T-Shirt',
  productGroupID: 'TSHIRT-001',
  variesBy: ['https://schema.org/color', 'https://schema.org/size'],
  hasVariant: [
    { '@type': 'Product', sku: 'TSHIRT-001-RED-M', color: 'Red', size: 'M' },
    { '@type': 'Product', sku: 'TSHIRT-001-BLU-L', color: 'Blue', size: 'L' },
  ],
};
```

### Article Schema

```typescript
const articleSchema = {
  '@context': 'https://schema.org',
  '@type': 'Article',
  headline: 'Article Title',
  description: 'Article description',
  image: 'https://your-site.com/article-image.jpg',
  datePublished: 'YYYY-MM-DDT08:00:00+00:00', // set dynamically from the CMS, not hardcoded
  dateModified: 'YYYY-MM-DDT10:00:00+00:00', // set dynamically from the CMS, not hardcoded
  author: {
    '@type': 'Person',
    name: 'Author Name',
    url: 'https://author-website.com',
  },
  publisher: {
    '@type': 'Organization',
    name: 'Publisher Name',
    logo: {
      '@type': 'ImageObject',
      url: 'https://your-site.com/logo.png',
    },
  },
};
```

### BreadcrumbList Schema

```typescript
const breadcrumbSchema = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    {
      '@type': 'ListItem',
      position: 1,
      name: 'Home',
      item: 'https://your-site.com',
    },
    {
      '@type': 'ListItem',
      position: 2,
      name: 'Products',
      item: 'https://your-site.com/products',
    },
    {
      '@type': 'ListItem',
      position: 3,
      name: 'Product Name',
      item: 'https://your-site.com/products/product-slug',
    },
  ],
};
```

## Deprecated / no longer rich-result-eligible

Do **not** implement these for SERP rich results — Google no longer renders them:

- **FAQ** — removed for all sites as of 2026-05-07.
- **HowTo** — deprecated September 2023.
- The 6 features Google retired in 2025 (Book Actions was initially on this list but was un-deprecated in June 2025 — it remains limited to large book providers):
  - Course Info
  - Claim Review / Fact Check
  - Estimated Salary
  - Learning Video
  - Special Announcement
  - Vehicle Listing
- **Practice Problems** — deprecated June 2025; support fully removed January 2026.
- **Dataset** markup is only used by [Dataset Search](https://datasetsearch.research.google.com/), not Google Search results (clarified November 2025).

You may still emit some of these as machine-readable signals (e.g. for AI / LLM extraction), but expect zero visible SERP enhancement from Google.

## Which schema types still drive rich results (2026)

Google's [Search Gallery](https://developers.google.com/search/docs/appearance/structured-data/search-gallery) is the source of truth for which structured-data types are currently eligible for rich results — check it before investing in any schema. High-value types for typical Next.js sites:

- **Product / merchant listing** — product snippets and shopping results
- **Review snippet** — star ratings
- **Breadcrumb** — breadcrumb trail in SERP
- **Article** — news/blog/article enhancements
- **Recipe**
- **Event**
- **Video**
- **Organization** — logo / knowledge panel signals
- **LocalBusiness**
- **Job posting**
- **Software app**

## @graph multi-entity pattern

Use a single `<script type="application/ld+json">` with an `@graph` array to wire multiple entities together via `@id` cross-references. This avoids duplicating the Organization on every page and lets Google connect the dots:

```json
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://your-site.com/#organization",
      "name": "Company Name",
      "url": "https://your-site.com",
      "logo": "https://your-site.com/logo.png"
    },
    {
      "@type": "WebSite",
      "@id": "https://your-site.com/#website",
      "url": "https://your-site.com",
      "name": "Site Name",
      "publisher": { "@id": "https://your-site.com/#organization" }
    },
    {
      "@type": "WebPage",
      "@id": "https://your-site.com/products/product-slug/#webpage",
      "url": "https://your-site.com/products/product-slug",
      "name": "Product Name",
      "isPartOf": { "@id": "https://your-site.com/#website" },
      "breadcrumb": { "@id": "https://your-site.com/products/product-slug/#breadcrumb" }
    },
    {
      "@type": "BreadcrumbList",
      "@id": "https://your-site.com/products/product-slug/#breadcrumb",
      "itemListElement": [
        { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://your-site.com" },
        { "@type": "ListItem", "position": 2, "name": "Products", "item": "https://your-site.com/products" },
        { "@type": "ListItem", "position": 3, "name": "Product Name", "item": "https://your-site.com/products/product-slug" }
      ]
    }
  ]
}
```

## Structured data for AI search

Schema is **not required** for AI Overviews — Google has stated structured data is not needed to appear in AI Overviews. Still, well-formed JSON-LD that matches the visible page plausibly helps AI systems parse, ground, and cite your content. Frame this as a correlation / trust signal, **not** a confirmed ranking factor. See [ai-search.md](ai-search.md) for AI-search and GEO guidance.

> Caveat: the Rich Results Test only validates currently-supported types, so valid FAQ/HowTo markup will correctly show "no eligible rich results" — that is expected, not an error.

## Usage in Next.js

```typescript
// app/layout.tsx
import { JsonLd } from '@/components/seo/json-ld';

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <JsonLd data={websiteSchema} />
        <JsonLd data={organizationSchema} />
        {children}
      </body>
    </html>
  );
}
```

## Testing Tools

1. **Google Rich Results Test**: https://search.google.com/test/rich-results
2. **Schema.org Validator**: https://validator.schema.org/
3. **JSON-LD Playground**: https://json-ld.org/playground/

## Best Practices

1. **Match visible content** - JSON-LD must reflect what users see
2. **Use XSS protection** - Always escape `<` characters
3. **Don't duplicate** - One schema type per page (except @graph)
4. **Keep updated** - Update dateModified when content changes
5. **Test regularly** - Validate after changes
