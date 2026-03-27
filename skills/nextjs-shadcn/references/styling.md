# Styling

## Theme System

### globals.css Structure

shadcn generates base variables automatically based on your chosen preset. Customize for your project:

```css
@import "tailwindcss";

/* Note: Tailwind v3 projects use @tailwind base; @tailwind components; @tailwind utilities; instead */

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

### Theme Customization

Quick customizations in `globals.css`:

```css
:root {
  /* Typography - change fonts */
  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-serif: Georgia, serif;
  --font-mono: "Fira Code", ui-monospace, monospace;

  /* Border radius - affects all rounded corners */
  --radius: 0.5rem;       /* Default */
  /* --radius: 0.25rem;   /* Sharp */
  /* --radius: 0.75rem;   /* More rounded */
  /* --radius: 1rem;      /* Very rounded */
  /* --radius: 1.3rem;    /* Pill-like buttons */
}
```

| Variable | Effect |
|----------|--------|
| `--font-sans` | Body text, buttons, inputs |
| `--font-mono` | Code blocks, technical content |
| `--radius` | All rounded corners (buttons, cards, inputs) |

**Tip**: Larger `--radius` values (1rem+) give a softer, more modern look. Smaller values (0.25rem) feel sharper and technical.

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
| vega | Classic shadcn/ui look. Clean, neutral, familiar |
| nova | Reduced padding and margins for compact layouts |
| maia | Soft and rounded, with generous spacing |
| lyra | Boxy and sharp. Pairs well with mono fonts |
| mira | Compact. Made for dense interfaces |

### Fonts

Available fonts via `shadcn create` preset URL:

| Font | Type | Character |
|------|------|-----------|
| geist-sans | Sans | Vercel's modern geometric sans |
| inter | Sans | Clean, versatile (classic default) |
| figtree | Sans | Friendly, geometric |
| dm-sans | Sans | Compact geometric with character |
| outfit | Sans | Modern, soft |
| noto-sans | Sans | Universal language support |
| nunito-sans | Sans | Rounded, approachable |
| roboto | Sans | Google's versatile sans |
| raleway | Sans | Elegant, thin-weight display |
| public-sans | Sans | US government standard, neutral |
| jetbrains-mono | Mono | Developer-focused monospace |

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
  Next <ChevronRight data-icon="inline-end" />
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

import { motion, HTMLMotionProps } from "motion/react"

interface FadeInProps extends HTMLMotionProps<"div"> {
  delay?: number
  duration?: number
  direction?: "up" | "down" | "left" | "right" | "none"
}

export function FadeIn({
  children,
  className,
  delay = 0,
  duration = 0.5,
  direction = "up",
  ...props
}: FadeInProps) {
  const directions = {
    up: { y: 20, x: 0 },
    down: { y: -20, x: 0 },
    left: { x: 20, y: 0 },
    right: { x: -20, y: 0 },
    none: { x: 0, y: 0 },
  }

  return (
    <motion.div
      initial={{ opacity: 0, ...directions[direction] }}
      whileInView={{ opacity: 1, x: 0, y: 0 }}
      viewport={{ once: true, margin: "-50px" }}
      transition={{ duration, delay, ease: "easeOut" }}
      className={className}
      {...props}
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

```text
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

## Decorative Backgrounds

Reusable patterns for visual atmosphere and section hierarchy.

### Grid Pattern

```tsx
import { cn } from "@/lib/utils"

export function GridBackground({
  children,
  className,
  size = 20
}: {
  children: React.ReactNode
  className?: string
  size?: number
}) {
  return (
    <div className={cn("relative", className)}>
      <div
        className={cn(
          "absolute inset-0 -z-10",
          "[background-image:linear-gradient(to_right,hsl(var(--border))_1px,transparent_1px),linear-gradient(to_bottom,hsl(var(--border))_1px,transparent_1px)]"
        )}
        style={{ backgroundSize: `${size}px ${size}px` }}
      />
      {children}
    </div>
  )
}
```

### Dot Pattern

```tsx
export function DotBackground({
  children,
  className
}: {
  children: React.ReactNode
  className?: string
}) {
  return (
    <div className={cn("relative", className)}>
      <div
        className={cn(
          "absolute inset-0 -z-10",
          "[background-size:20px_20px]",
          "[background-image:radial-gradient(hsl(var(--muted-foreground)/0.3)_1px,transparent_1px)]"
        )}
      />
      {children}
    </div>
  )
}
```

### Radial Gradient Hero

```tsx
export function GradientHero({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative min-h-screen">
      <div
        aria-hidden
        className="fixed inset-0 -z-10"
        style={{
          background: "radial-gradient(125% 125% at 50% 10%, hsl(var(--background)) 40%, hsl(var(--primary)) 100%)"
        }}
      />
      {children}
    </div>
  )
}
```

### Faded Edge Effect

Combine with grid/dot for vignette:

```tsx
<div className="relative">
  <GridBackground className="absolute inset-0" />
  <div className="pointer-events-none absolute inset-0 bg-background [mask-image:radial-gradient(ellipse_at_center,transparent_20%,black)]" />
  {/* Content */}
</div>
```

### Animated Spotlight

For premium hero sections. Requires `motion`:

```tsx
"use client"

import { motion } from "motion/react"
import { cn } from "@/lib/utils"

export function Spotlight({ className }: { className?: string }) {
  return (
    <motion.div
      className={cn(
        "pointer-events-none fixed inset-0 -z-10 overflow-hidden",
        className
      )}
      aria-hidden
    >
      <motion.div
        className="absolute top-0 left-1/2 h-[60vh] w-[80vw] -translate-x-1/2 rounded-full opacity-20 blur-3xl"
        style={{
          background:
            "radial-gradient(ellipse, hsl(var(--primary) / 0.3), transparent 70%)",
        }}
        animate={{ x: ["-10%", "10%", "-10%"] }}
        transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
      />
    </motion.div>
  )
}
```

Combine with DotBackground for depth:

```tsx
<div className="relative min-h-screen bg-background dark:bg-black">
  <Spotlight />
  <DotBackground className="absolute inset-0 opacity-30" />
  <div className="relative z-10">{children}</div>
</div>
```

For more creative direction (custom textures, particles, dramatic effects), apply `/frontend-design` thinking.

### Section Wrapper

For sections that need different theme context:

```tsx
type SectionProps = {
  children: React.ReactNode
  variant?: "default" | "muted" | "inverted"
  className?: string
}

export function Section({ children, variant = "default", className }: SectionProps) {
  return (
    <section
      className={cn(
        "relative py-24",
        variant === "muted" && "bg-muted",
        variant === "inverted" && "bg-foreground text-background [&_*]:border-background/20",
        className
      )}
    >
      {children}
    </section>
  )
}
```

### Background Decision Tree

```text
Full-page ambient effect?
├── Static → Fixed radial gradient (GradientHero)
├── Animated → Spotlight + DotBackground
├── Premium → Apply /frontend-design thinking
└── No ↓

Subtle texture for depth?
├── Grid → Technical/dashboard feel
├── Dots → Softer/organic feel
└── No ↓

Section contrast needed?
├── Yes → Section wrapper with variant
└── No → Standard bg-background
```

### File Organization

```text
components/
├── ui/           # shadcn primitives
├── backgrounds/  # Grid, Dot, Gradient patterns
└── animations/   # FadeIn, ScrollReveal
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
