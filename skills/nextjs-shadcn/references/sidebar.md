# Sidebar integration

Use this when a Next.js app needs shared navigation or a collapsible sidebar. Read `shadcn docs sidebar` with the project's package runner for its actual primitive base and current API.

## Layout ownership

Put `SidebarProvider`, shared navigation and its trigger in the layout that owns the relevant routes. Keep each page's content in `children`. Use `SidebarInset` when the chosen sidebar variant calls for it.

Keep navigation data separate when multiple views use it. Follow the existing aliases and icon family; avoid creating a new global folder structure for one navigation component.

The provider is a Client Component and may wrap Server-rendered content. This is a valid broader client boundary; it does not require every page to become a Client Component.

## Links and state

Base UI composes custom elements through `render`; Radix commonly uses `asChild`. Use the project's installed API rather than mixing the two.

Keep selected state and labels clear. An icon rail needs accessible names and a usable way to expand on touch and keyboard. Use `useSidebar()` for custom triggers and mobile state where appropriate.

With Cache Components, a navigation component that reads `usePathname` for the active link suspends under any route whose dynamic params `generateStaticParams` does not cover, and the build fails without a boundary. Wrap that component in Suspense with a static fallback rather than the whole layout.

To persist open state without a hydration mismatch, read the sidebar cookie in the layout Server Component and pass `defaultOpen` to the provider. Use controlled `open` and `onOpenChange` only when the app needs to own the state.

Choose width, collapse behavior and `sidebar`, `floating` or `inset` variants for the content. A sidebar should give users context without reducing the working area unnecessarily.

## RTL and verification

Use the project's direction support and logical spacing utilities when RTL is relevant. Verify narrow-screen navigation, longest labels, active links, collapsed tooltips, focus and page overflow.

Official APIs: [Base UI sidebar](https://ui.shadcn.com/docs/components/base/sidebar), [Radix sidebar](https://ui.shadcn.com/docs/components/radix/sidebar).
