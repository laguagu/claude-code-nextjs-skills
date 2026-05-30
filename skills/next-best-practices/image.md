# Image Optimization

Use `next/image` for automatic image optimization.

## Always Use next/image

```tsx
// Bad: Avoid native img
<img src="/hero.png" alt="Hero" />

// Good: Use next/image
import Image from 'next/image'
<Image src="/hero.png" alt="Hero" width={800} height={400} />
```

## Required Props

Images need explicit dimensions to prevent layout shift:

```tsx
// Local images - dimensions inferred automatically
import heroImage from './hero.png'
<Image src={heroImage} alt="Hero" />

// Remote images - must specify width/height
<Image src="https://example.com/image.jpg" alt="Hero" width={800} height={400} />

// Or use fill for parent-relative sizing
<div style={{ position: 'relative', width: '100%', height: 400 }}>
  <Image src="/hero.png" alt="Hero" fill style={{ objectFit: 'cover' }} />
</div>
```

## Remote Images Configuration

Remote domains must be configured in `next.config.js`:

```js
// next.config.js
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
        pathname: '/images/**',
      },
      {
        protocol: 'https',
        hostname: '*.cdn.com', // Wildcard subdomain
      },
    ],
  },
}
```

## Next.js 16 Config Changes

Several `images` defaults changed in v16 — be aware when reviewing/upgrading:

```js
// next.config.ts
const nextConfig = {
  images: {
    // quality is now coerced to the closest value in this list.
    // Default changed from [1..100] to [75]. Add any other quality you use:
    qualities: [50, 75, 90],

    // Required to optimize LOCAL images whose `src` has a query string
    // (v16 security change to prevent enumeration attacks).
    localPatterns: [{ pathname: '/assets/**', search: '' }],

    // Default changed from 60s to 4 hours (14400). Tune as needed.
    minimumCacheTTL: 14400,
  },
}
```

- `images.domains` is **deprecated** — always use `remotePatterns` (below).
- `next/legacy/image` is deprecated — use `next/image`.
- `<Image quality={90} />` requires `90` to be present in `images.qualities`,
  otherwise it is coerced to the nearest configured value.

## Responsive Images

Use `sizes` to tell the browser which size to download:

```tsx
// Full-width hero
<Image
  src="/hero.png"
  alt="Hero"
  fill
  sizes="100vw"
/>

// Responsive grid (3 columns on desktop, 1 on mobile)
<Image
  src="/card.png"
  alt="Card"
  fill
  sizes="(max-width: 768px) 100vw, 33vw"
/>

// Fixed sidebar image
<Image
  src="/avatar.png"
  alt="Avatar"
  width={200}
  height={200}
  sizes="200px"
/>
```

## Blur Placeholder

Prevent layout shift with placeholders:

```tsx
// Local images - automatic blur hash
import heroImage from './hero.png'
<Image src={heroImage} alt="Hero" placeholder="blur" />

// Remote images - provide blurDataURL
<Image
  src="https://example.com/image.jpg"
  alt="Hero"
  width={800}
  height={400}
  placeholder="blur"
  blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRg..."
/>

// Or use color placeholder
<Image
  src="https://example.com/image.jpg"
  alt="Hero"
  width={800}
  height={400}
  placeholder="empty"
  style={{ backgroundColor: '#e0e0e0' }}
/>
```

## Priority Loading

Use `priority` for above-the-fold images (LCP):

```tsx
// Hero image - loads immediately
<Image src="/hero.png" alt="Hero" fill priority />

// Below-fold images - lazy loaded by default (no priority needed)
<Image src="/card.png" alt="Card" width={400} height={300} />
```

## Common Mistakes

```tsx
// Bad: Missing sizes with fill - downloads largest image
<Image src="/hero.png" alt="Hero" fill />

// Good: Add sizes for proper responsive behavior
<Image src="/hero.png" alt="Hero" fill sizes="100vw" />

// Bad: Using width/height for aspect ratio only
<Image src="/hero.png" alt="Hero" width={16} height={9} />

// Good: Use actual display dimensions or fill with sizes
<Image src="/hero.png" alt="Hero" fill sizes="100vw" style={{ objectFit: 'cover' }} />

// Bad: Remote image without config
<Image src="https://untrusted.com/image.jpg" alt="Image" width={400} height={300} />
// Error: Invalid src prop, hostname not configured

// Good: Add hostname to next.config.js remotePatterns
```

## Static Export

When using `output: 'export'`, use `unoptimized` or custom loader:

```tsx
// Option 1: Disable optimization
<Image src="/hero.png" alt="Hero" width={800} height={400} unoptimized />

// Option 2: Global config
// next.config.js
module.exports = {
  output: 'export',
  images: { unoptimized: true },
}

// Option 3: Custom loader (Cloudinary, Imgix, etc.)
const cloudinaryLoader = ({ src, width, quality }) => {
  return `https://res.cloudinary.com/demo/image/upload/w_${width},q_${quality || 75}/${src}`
}

<Image loader={cloudinaryLoader} src="sample.jpg" alt="Sample" width={800} height={400} />
```
