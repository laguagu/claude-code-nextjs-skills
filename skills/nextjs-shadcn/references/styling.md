# Styling

## Theme System

### globals.css Structure

shadcn generates base variables automatically based on your chosen preset. Customize for your project:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    /* shadcn base variables come from preset */
    --background: ...;
    --foreground: ...;
    --primary: ...;
    --secondary: ...;
    /* etc. */

    /* Add your own variables as needed */
    --brand: 220 90% 56%;
    --brand-foreground: 0 0% 100%;
    --accent-2: 160 60% 45%;
  }

  .dark {
    /* Dark mode variants */
  }
}
```

**Choose preset**: Use [ui.shadcn.com/create](https://ui.shadcn.com/create) to select theme (vega, nova, maia, lyra, mira) and colors.

### Using Theme Colors

```tsx
// ✅ Use CSS variables
<div className="bg-primary text-primary-foreground" />
<div className="border-border" />
<div className="text-muted-foreground" />

// ❌ Never hardcode colors
<div className="bg-blue-500" />
<div className="text-[#1a1a1a]" />
```

## shadcn/ui Presets

Available styles at ui.shadcn.com/create:

| Preset | Character |
|--------|-----------|
| vega | Clean, minimal |
| nova | Bold, modern |
| maia | Soft, organic |
| lyra | Sharp, technical |
| mira | Balanced, neutral |

## Icon Libraries

Priority order (use first available):

1. **lucide** (default) - `bun add lucide-react`
2. **tabler** - `bun add @tabler/icons-react`
3. **hugeicons** - `bun add hugeicons-react`
4. **phosphor** - `bun add @phosphor-icons/react`

```tsx
// lucide example
import { ChevronRight, Menu, X } from "lucide-react"

<Button>
  Next <ChevronRight className="ml-2 h-4 w-4" />
</Button>
```

## Animations

### CSS Page Transitions

Add to `globals.css`:

```css
@keyframes page-in {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@layer utilities {
  .animate-page-in {
    animation: page-in 0.6s ease-out both;
  }
}
```

Usage in layout or template:

```tsx
// template.tsx - animates on every navigation
export default function Template({ children }: { children: React.ReactNode }) {
  return <main className="animate-page-in">{children}</main>
}
```

### View Transitions API

Next.js built-in support (works with `<Link>`):

```ts
// next.config.ts
import type { NextConfig } from "next"

const config: NextConfig = {
  experimental: {
    viewTransition: true
  }
}

export default config
```

Use `<Link>` normally - transitions work automatically:

```tsx
import Link from "next/link"

<Link href="/about">About</Link>
```

### Motion Library

For complex animations:

```bash
bun add motion
```

```tsx
"use client"

import { motion } from "motion/react"

export function FadeIn({ children }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
    >
      {children}
    </motion.div>
  )
}
```

### GSAP

For scroll-triggered and complex sequences:

```bash
bun add gsap @gsap/react
```

```tsx
"use client"

import { useRef } from "react"
import { useGSAP } from "@gsap/react"
import gsap from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"

gsap.registerPlugin(ScrollTrigger)

export function ScrollReveal({ children }) {
  const containerRef = useRef<HTMLDivElement>(null)

  useGSAP(() => {
    gsap.from(containerRef.current, {
      opacity: 0,
      y: 50,
      scrollTrigger: {
        trigger: containerRef.current,
        start: "top 80%",
      },
    })
  }, [])

  return <div ref={containerRef}>{children}</div>
}
```

## Animation Decision Tree

```
Simple fade/slide on mount?
├── Yes → CSS animation in globals.css
└── No ↓

Page/route transitions?
├── Yes → View Transitions API or template.tsx
└── No ↓

Interactive hover/tap states?
├── Yes → Tailwind transitions + Motion
└── No ↓

Scroll-triggered sequences?
├── Yes → GSAP + ScrollTrigger
└── No → Evaluate if animation needed
```

## Performance Tips

1. **Prefer CSS** - GPU-accelerated, no JS bundle
2. **Use `will-change` sparingly** - Only for known animations
3. **Avoid layout thrashing** - Animate `transform` and `opacity`
4. **Lazy load Motion/GSAP** - Dynamic imports for non-critical animations

```tsx
// Lazy load animation library
const MotionDiv = dynamic(
  () => import("motion/react").then((mod) => mod.motion.div),
  { ssr: false }
)
```

## Optional Utilities

### Scrollbar Hide

Hide scrollbar while preserving scroll functionality:

```bash
bun add tailwind-scrollbar-hide
```

```ts
// tailwind.config.ts
import scrollbarHide from "tailwind-scrollbar-hide"

export default {
  plugins: [scrollbarHide],
}
```

```tsx
<div className="overflow-y-auto scrollbar-hide">
  {/* Scrollable content without visible scrollbar */}
</div>
```
