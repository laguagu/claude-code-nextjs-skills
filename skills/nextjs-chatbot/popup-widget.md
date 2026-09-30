# Popup and embedded chat

Choose a full page, inline panel, popup or iframe from the host application's
needs. A widget does not require a Lottie cue, decorative glow, hidden scrollbar
or permanently visible prompt chips.

Keep the composer reachable while history scrolls. A flex/grid chain with
bounded height and `min-height: 0` on the scrolling child prevents messages from
pushing the input out of the panel. Test narrow screens, virtual keyboards,
long tool results and safe-area insets.

Give the launcher an accessible name and clear open state. Opening/closing
must manage focus appropriately; provide keyboard dismissal and return focus
to the launcher when relevant. Announce useful state without reading every
streamed token. Preserve the reader's position when they leave the bottom.

## Embedding boundary

An iframe isolates styles, but adds a cross-origin integration contract.
Configure permitted embedding origins with CSP `frame-ancestors`; account for
other frame restrictions and the application's authentication/cookie policy.
Do not loosen the whole application's policy solely for a widget.

Validate `postMessage` origins and message shapes on both sides; use a specific
target origin. Never treat a parent-supplied user, tenant, consent or API key as
trusted without server validation.

A loader script should mount once, avoid conflicting host styles and expose a
deliberate open/close/unmount interface. Keep secrets server-side. Verify the
real host page, permitted and rejected origins, keyboard flow, mobile layout
and streaming through the deployed proxy.

Use `nextjs-shadcn` for visual decisions and
[persistence.md](persistence.md) for conversation lifetime.
