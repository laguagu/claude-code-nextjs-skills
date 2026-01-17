# Project Setup

## Create New Project

### With Preset (Recommended)

```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=vega&iconLibrary=lucide" \
  --template next
```

### Full Preset URL Options

```
https://ui.shadcn.com/init?
  base=radix
  &style=vega|nova|maia|lyra|mira
  &baseColor=neutral|slate|gray|zinc|stone
  &theme=neutral|blue|green|orange|red|rose|violet
  &iconLibrary=lucide|tabler|hugeicons|phosphor
  &font=inter|geist|system
  &menuAccent=subtle|bold
  &menuColor=default|accent
  &radius=default|sm|md|lg|xl
  &template=next
```

### Example Presets

**Minimal (vega + lucide)**:
```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=vega&iconLibrary=lucide&font=inter" \
  --template next
```

**Bold (nova + tabler)**:
```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=nova&iconLibrary=tabler&theme=violet" \
  --template next
```

**Soft (maia + phosphor)**:
```bash
bunx --bun shadcn@latest create \
  --preset "https://ui.shadcn.com/init?base=radix&style=maia&iconLibrary=phosphor&radius=lg" \
  --template next
```

## Add Components

```bash
# Single component
bunx --bun shadcn@latest add button

# Multiple components
bunx --bun shadcn@latest add button card input

# All components
bunx --bun shadcn@latest add --all
```

## Common Dependencies

```bash
# Forms
bun add react-hook-form @hookform/resolvers zod

# AI
bun add ai @ai-sdk/anthropic

# Animation
bun add motion              # For Motion
bun add gsap @gsap/react    # For GSAP

# Icons (pick one)
bun add lucide-react        # Default
```

## Project Structure After Setup

```
project/
├── app/
│   ├── globals.css         # Theme tokens
│   ├── layout.tsx          # Root layout
│   └── page.tsx            # Home page
├── components/
│   └── ui/                 # shadcn components
├── lib/
│   └── utils.ts            # cn() helper
├── public/
├── components.json         # shadcn config
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## Bun Commands Reference

| Task | Command |
|------|---------|
| Install deps | `bun install` |
| Add package | `bun add package` |
| Dev server | `bun --bun next dev` |
| Build | `bun --bun next build` |
| Start prod | `bun --bun next start` |
| Add shadcn component | `bunx --bun shadcn@latest add component` |
| Create project | `bunx --bun shadcn@latest create ...` |

