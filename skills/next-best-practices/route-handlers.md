# Route Handler contracts

A `route.ts` owns HTTP handling at its route; it cannot coexist with a
`page.tsx` for that same segment. It is not a React render context.

Set auth, validation, response content type, cache policy and cancellation for
the actual endpoint. Do not assume every Route Handler has Node.js APIs if the
project selected another runtime.

GET is uncached by default (since 15); without Cache Components,
`export const dynamic = 'force-static'` opts it in. With Cache Components, GET
prerenders unless it reads the request or uncached data, and `use cache` must
live in a helper, not the handler. Other methods are never cached. Type the
context as `RouteContext<'/users/[id]'>`.

For a streamed response, proxies and terminal errors matter after HTTP headers
are sent. Returning an async stream is not itself a durable job.

Read `01-getting-started/15-route-handlers.md`,
`03-api-reference/03-file-conventions/route.md` and the project's API
conventions rather than copying a generic CRUD handler.
