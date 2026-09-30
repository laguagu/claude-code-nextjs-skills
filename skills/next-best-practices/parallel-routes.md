# Parallel and intercepted navigation

Slots render in the owning layout. Provide documented fallback/default behavior
for hard navigation and unmatched slots, including implicit children where
needed. In Next.js 16, every named slot requires `default.tsx` or the build
fails; return `null` or call `notFound()` for the intended fallback. An unmatched
implicit `children` slot without a default returns 404 on hard navigation.

Interceptors count route segments, not filesystem folders. A direct visit to an
intercepted URL normally renders its full page; a client transition can show a
modal. Implement both paths.

`router.back()` is useful for closing a modal opened by navigation. Closing or
navigating elsewhere must also clear the slot; use documented null/catch-all
routes where needed. A persistent modal is not always caused by using push.

Test open, close, forward/back, direct load and refresh, including nested
slots and route groups. Respect accessibility/focus behavior of the chosen dialog.

Read [Parallel Routes](https://nextjs.org/docs/app/api-reference/file-conventions/parallel-routes)
and [Intercepting Routes](https://nextjs.org/docs/app/api-reference/file-conventions/intercepting-routes).
