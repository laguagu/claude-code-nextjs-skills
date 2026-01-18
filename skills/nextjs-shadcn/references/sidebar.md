# Sidebar

shadcn/ui sidebar with nested layouts for dashboard applications.

## Installation

```bash
bunx --bun shadcn@latest add sidebar
```

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
  SidebarRail,
} from "@/components/ui/sidebar"

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarRail />
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
| `default` | Standard sidebar |
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

## File Structure

```
components/
└── layout/
    ├── app-sidebar.tsx    # Sidebar component
    └── nav.ts             # Navigation config
```
