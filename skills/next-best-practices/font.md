# Font delivery

Choose typography for the product's language, density and tone. Use the existing
font setup or `next/font` where it fits; no family is mandatory.

Load only needed weights/styles and ensure glyph coverage. Shared loader
instances prevent redundant downloads; route-specific fonts need not preload
globally. Verify fallback metrics, font display and CSP/network behavior in
the actual environment.

`next/font` can reduce layout shift, but it does not prove zero CLS for the
page. Google-font build downloads may be unavailable in restricted environments;
use real local licensed assets when that is the deployment contract.

Read the installed [font reference](https://nextjs.org/docs/app/api-reference/components/font)
for framework/Tailwind integration rather than copying version-specific theme code.
