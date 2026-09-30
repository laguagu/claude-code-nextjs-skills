# Image delivery

Prefer the project's `next/image` setup where optimization fits; SVG, external
loaders, authenticated images or static export may need a different delivery
contract. A blanket component substitution can break those cases.

Reserve layout space with intrinsic dimensions or a sized `fill` container.
Use accurate responsive `sizes`; placeholders do not reserve space on their
own. Set useful alt text or empty alt for decoration.

Restrict `images.remotePatterns` to intended sources (`images.domains` is
deprecated). Static export needs an appropriate loader or unoptimized delivery.

Next.js 16 defaults: `images.qualities` is `[75]`, so another `quality` prop is
coerced to the nearest allowed value unless configured; local `src` with a
query string needs `images.localPatterns[].search`; `minimumCacheTTL` is 4 h;
local-IP upstreams are blocked; at most 3 redirects.

Load the actual LCP image early without preloading every hero candidate.
`priority` is deprecated (16) in favor of `preload`; usually prefer
`loading="eager"` or `fetchPriority="high"`. Read
`03-api-reference/02-components/image.md`.

Measure delivered dimensions/bytes and layout shift in the real responsive view.
