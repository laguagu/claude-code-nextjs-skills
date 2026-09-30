# Image delivery

Prefer the project's `next/image` setup where optimization fits; SVG, external
loaders, authenticated images or static export may need a different delivery
contract. A blanket component substitution can break those cases.

Reserve layout space with intrinsic dimensions or a sized `fill` container.
Use accurate responsive `sizes`; placeholders do not reserve space on their
own. Set useful alt text or empty alt for decoration.

Restrict remote patterns to intended sources. Verify loader, SVG and quality
allowlist behavior in the installed version. Static export needs an appropriate
loader or unoptimized delivery.

Load the actual LCP image early without preloading every hero candidate. Current
Next.js favors eager/fetchPriority in many cases and deprecates `priority`;
choose from the installed [Image reference](https://nextjs.org/docs/app/api-reference/components/image).

Measure delivered dimensions/bytes and layout shift in the real responsive view.
