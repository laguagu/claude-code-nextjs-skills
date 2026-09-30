# Font delivery

Keep the existing font setup; `next/font` is the default when adding one.
Call each loader once in a shared module: every call is a separate instance.
Load only needed weights/subsets; route-specific fonts need not preload
globally.

`next/font` can reduce layout shift, but it does not prove zero CLS for the
page. Google-font build downloads may be unavailable in restricted environments;
use real local licensed assets when that is the deployment contract.

Read `03-api-reference/02-components/font.md` for the CSS-variable/Tailwind
integration rather than copying version-specific theme code.
