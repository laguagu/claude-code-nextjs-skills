# Typography, themes and atmosphere

Use this when choosing the visual language or adding backgrounds, media and motion. Preserve the existing design system unless the brief calls for changing it.

## Typography and style

Choose type for the actual product: a reading surface needs comfortable paragraphs; a dashboard needs compact, legible labels; a brand page may benefit from expressive display type. Match the language's glyph coverage and distinguish headings, body and numerical data where useful.

No font family is universally required or forbidden. A familiar family can be the right choice. Judge the rendered result: wrapping, line length, weights, loading behavior and hierarchy.

For Next.js, use `next/font` where appropriate or the project's existing font setup. Set the chosen fonts through the theme so components inherit them. Choose a preset through [shadcn/create](https://ui.shadcn.com/create), using its current options rather than a fixed list in this skill. Offline, `shadcn preset decode <code>` shows a code's style, fonts, icon library and radius, and the installed `shadcn/preset` module exports the option lists (`PRESET_STYLES`, `PRESET_FONTS`, `PRESET_ICON_LIBRARIES`).

## Theme ownership

Use semantic colors such as `bg-background`, `text-foreground` and `text-muted-foreground`. Customize the generated theme and component variants rather than restyling each instance.

With Tailwind v4, a custom variable generates utilities only through a theme mapping: `--brand` in `:root`/`.dark` needs `@theme inline { --color-brand: var(--brand); }` before `bg-brand` exists. For other token mappings, read the [Tailwind theme guidance](https://tailwindcss.com/docs/theme). Preserve the generated theme's conventions for dark mode and existing projects on older Tailwind versions.

Theme modes, accent colors and corner radii follow the brief and component hierarchy. Do not add a second mode or force a single radius onto every component just to satisfy a template.

## Background repertoire

Pick what serves the composition; these are possibilities, not a checklist.

| Treatment | Useful purpose | Implementation direction |
|---|---|---|
| Grid | Structure, technical character or spatial context | Two perpendicular CSS linear gradients |
| Dots | Quiet texture or a softer technical surface | CSS radial gradient with controlled spacing |
| Radial light or glow | Emphasis behind a hero, product or focal point | Layered radial gradients using theme colors |
| Custom shapes or patterns | A visual motif specific to the subject | CSS, SVG or a sourced asset suited to the geometry |
| Grain or texture | Material character | A restrained static texture layer |
| Illustration or photography | Explain the subject or establish its world | Real assets or purpose-made image generation |
| Video or richer scene | Demonstrate a product or tell a visual story | Suitable footage, generated clips or a purposeful canvas |

Adjust scale, position and opacity to the layout rather than using the same full-page effect for every app. A pattern can fade with a mask or stay within one section; it need not cover the whole page.

Keep decorative layers out of the reading and interaction paths: `aria-hidden`, `pointer-events: none`, deliberate stacking and enough contrast on the final composite. Contain overflow at its source instead of hiding page overflow to conceal a layout bug.

## Media and motion

Use available generation tools when an original illustration, image or video would improve the design. Inspect the result for relevance, legibility and fit. Reuse existing assets when they already do the job. Use `icons` for real brand marks; a generated image is not evidence of a customer's endorsement or a factual product screenshot.

For video backgrounds, preserve readability, reserve space and provide a useful poster or static fallback. Avoid unsolicited audio and excessive media weight. Prefer an actual UI preview when the visitor needs to understand how the product works.

Start with the project's existing result, disclosure and navigation components. For size/position changes or a moving active selection, consult [Motion's layout documentation](https://motion.dev/docs/react-layout-animations) when that library fits the project. For route or shared-element continuity, use `vercel-react-view-transitions` and the current [React ViewTransition reference](https://react.dev/reference/react/ViewTransition); check support in the installed framework's docs. No particular animation library is required.

Respect reduced motion. Keep essential content visible without animation, stop continuous work when offscreen or hidden, and check touch behavior. A pointer-following light, scroll sequence or canvas is an intentional feature, not a routine finishing step.

## Check the design as rendered

Inspect fonts after they settle, the actual contrast over effects and imagery, and the longest content at narrow widths. Judge whether the visual treatment makes the product clearer and more distinctive.

Design-system lint should support these choices. Scope its contracts and exceptions to custom visual layers when needed rather than removing a useful effect solely because a generic rule bans inline styles.

Sources: [shadcn theming](https://ui.shadcn.com/docs/theming), [Next.js fonts](https://nextjs.org/docs/app/api-reference/components/font), [View Transitions](https://nextjs.org/docs/app/guides/view-transitions).
