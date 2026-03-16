# Loader

A spinning SVG loader icon for indicating loading states in AI chat interfaces.

## Installation

```bash
bunx --bun ai-elements@latest add loader
```

## Usage

```tsx
import { Loader } from '@/components/ai-elements/loader';

// Show while waiting for AI response
{status === 'submitted' && <Loader />}

// Custom size
<Loader size={12} />

// With label
<div className="flex items-center gap-2 text-xs text-muted-foreground">
  <Loader size={12} />
  <span>Loading suggestions…</span>
</div>
```

## Props

### `<Loader />`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `size` | `number` | `16` | Width and height of the loader icon in pixels. |
| `...props` | `React.HTMLAttributes<HTMLDivElement>` | - | Any other props are spread to the wrapper div. |
