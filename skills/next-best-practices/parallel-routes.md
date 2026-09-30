# Parallel and intercepted navigation

Slots render in the owning layout. In 16 every named `@slot` needs a
`default.tsx` (return `null`, or call `notFound()` to keep the old 404), or the
build fails. Hard navigation renders `default` for unmatched slots; without a
`default` for the implicit `children` slot, it 404s.

Interceptors count route segments, not filesystem folders. A direct visit to an
intercepted URL normally renders its full page; a client transition can show a
modal. Implement both paths.

`router.back()` is useful for closing a modal opened by navigation. Closing or
navigating elsewhere must also clear the slot; use documented null/catch-all
routes where needed. A persistent modal is not always caused by using push.

Test open, close, forward/back, direct load and refresh, including nested
slots and route groups. Respect accessibility/focus behavior of the chosen dialog.

Read `parallel-routes.md`, `intercepting-routes.md` and `default.md` in
`03-api-reference/03-file-conventions/`.
