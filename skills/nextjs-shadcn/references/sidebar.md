# Sidebar

shadcn/ui sidebar with nested layouts for dashboard applications.

## Start from a block, not from scratch

Before hand-writing an `AppSidebar`, check whether a block already matches the
shape you need. A block installs a complete, working sidebar you then edit —
faster and less error-prone than assembling sub-components by hand.

```bash
bunx --bun shadcn@latest add sidebar-07
```

| Block | Shape |
|-------|-------|
| `sidebar-01` | Navigation grouped by section (simplest) |
| `sidebar-02` | Collapsible sections |
| `sidebar-03` | Submenus |
| `sidebar-04` | Floating sidebar with submenus |
| `sidebar-05` | Collapsible submenus |
| `sidebar-06` | Submenus as dropdowns |
| `sidebar-07` | Collapses to icons — the common dashboard default |
| `sidebar-08` | Inset sidebar with secondary navigation |
| `sidebar-09` | Collapsible nested sidebars |
| `sidebar-10` | Sidebar in a popover |
| `sidebar-11` | Collapsible file tree |
| `sidebar-12` | Sidebar with a calendar |
| `sidebar-13` | Sidebar in a dialog |
| `sidebar-14` | Sidebar on the right |
| `sidebar-15` | Left and right sidebar |
| `sidebar-16` | Sticky site header |

Preview them at [ui.shadcn.com/blocks/sidebar](https://ui.shadcn.com/blocks/sidebar).
Use `shadcn view sidebar-07` to read the source before installing.

The patterns below are for when no block fits, or when adapting one.

## Installation

```bash
bunx --bun shadcn@latest add sidebar
```

The sidebar API differs between Base UI, Radix and React Aria. Check the
project's base (`shadcn info --json`) and read
`shadcn docs sidebar` rather than assuming — the examples below target Base UI,
the current default.

## Layout Pattern

Use nested layouts with SidebarProvider for persistent sidebar state:

```
app/
├── (dashboard)/           # Route group for sidebar pages
│   ├── layout.tsx         # SidebarProvider + AppSidebar
│   ├── page.tsx           # Dashboard home
│   ├── settings/
│   │   └── page.tsx
│   └── components/        # Route-specific components
├── (public)/              # Public routes (no sidebar)
│   └── login/
└── layout.tsx             # Root layout
```

### Dashboard Layout

```tsx
// app/(dashboard)/layout.tsx
import { AppSidebar } from "@/components/layout/app-sidebar"
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar"

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset>{children}</SidebarInset>
    </SidebarProvider>
  )
}
```

### Page Component

Keep pages clean - content only, no layout chrome:

```tsx
// app/(dashboard)/page.tsx
import { DocumentWorkspace } from "@/components/workspace/document-workspace"
import { Suspense } from "react"

export default function DashboardPage() {
  return (
    <Suspense fallback={<DashboardSkeleton />}>
      <DocumentWorkspace />
    </Suspense>
  )
}
```

## AppSidebar Component

```tsx
// components/layout/app-sidebar.tsx
import Link from "next/link"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
  SidebarSeparator,
} from "@/components/ui/sidebar"
import { NAV_GROUPS, FOOTER_NAV_ITEMS } from "./nav"

export function AppSidebar() {
  return (
    <Sidebar variant="inset" collapsible="icon">
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton asChild size="lg">
              <Link href="/" className="flex items-center gap-3">
                <Logo className="size-8" />
                <span className="text-base font-semibold">App Name</span>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>

      <SidebarContent>
        {NAV_GROUPS.map((group, index) => (
          <div key={group.title}>
            <SidebarGroup>
              <SidebarGroupLabel>{group.title}</SidebarGroupLabel>
              <SidebarGroupContent>
                <SidebarMenu>
                  {group.items.map((item) => (
                    <SidebarMenuItem key={item.title}>
                      <SidebarMenuButton asChild>
                        <Link href={item.href}>
                          <item.icon />
                          <span>{item.title}</span>
                        </Link>
                      </SidebarMenuButton>
                    </SidebarMenuItem>
                  ))}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>
            {index < NAV_GROUPS.length - 1 && <SidebarSeparator />}
          </div>
        ))}
      </SidebarContent>

      <SidebarFooter>
        <SidebarSeparator />
        <SidebarMenu>
          {FOOTER_NAV_ITEMS.map((item) => (
            <SidebarMenuItem key={item.title}>
              <SidebarMenuButton asChild>
                <Link href={item.href}>
                  <item.icon />
                  <span>{item.title}</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          ))}
        </SidebarMenu>
      </SidebarFooter>

      <SidebarRail />
    </Sidebar>
  )
}
```

## Navigation Config

Separate navigation data from component:

```tsx
// components/layout/nav.ts
import { Home, Settings, Users, HelpCircle } from "lucide-react"
import type { LucideIcon } from "lucide-react"

interface NavItem {
  title: string
  href: string
  icon: LucideIcon
}

interface NavGroup {
  title: string
  items: NavItem[]
}

export const NAV_GROUPS: NavGroup[] = [
  {
    title: "Main",
    items: [
      { title: "Dashboard", href: "/", icon: Home },
      { title: "Users", href: "/users", icon: Users },
    ],
  },
]

export const FOOTER_NAV_ITEMS: NavItem[] = [
  { title: "Settings", href: "/settings", icon: Settings },
  { title: "Help", href: "/help", icon: HelpCircle },
]
```

## Sidebar Variants

| Variant | Description |
|---------|-------------|
| `sidebar` | Standard sidebar (default) |
| `inset` | Sidebar with padding, content area has rounded corners |
| `floating` | Sidebar floats over content |

```tsx
<Sidebar variant="inset" collapsible="icon">
```

## Collapsible Options

| Option | Behavior |
|--------|----------|
| `icon` | Collapses to icon-only rail |
| `offcanvas` | Slides completely off-screen |
| `none` | Not collapsible |

## RTL

`Sidebar` takes a `dir` prop and positions via `data-side` attributes, so
right-to-left layouts work without JS conditionals — `SidebarTrigger` flips its
icon automatically. Opt in project-wide at `init` with `--rtl`, or retrofit with
`shadcn migrate rtl`. In any project that might need RTL, use logical utilities
(`ms-`/`me-`, `ps-`/`pe-`) instead of `ml-`/`mr-` in sidebar markup.

## Persisting open state

`SidebarProvider` takes `defaultOpen` (uncontrolled) or `open` / `onOpenChange`
(controlled); width comes from the `--sidebar-width` CSS variable. To keep the
sidebar's state across reloads without a hydration mismatch, read a cookie in the
layout Server Component and pass it to `defaultOpen` — don't read it client-side
in an effect.

For custom triggers, `useSidebar()` exposes `toggleSidebar`, `isMobile`, and the
mobile-specific `openMobile` / `setOpenMobile`.

## File Structure

```
components/
└── layout/
    ├── app-sidebar.tsx    # Sidebar component
    └── nav.ts             # Navigation config
```
