# Route Handler contracts

A `route.ts` owns HTTP handling at its route; it cannot coexist with a
`page.tsx` for that same segment. It is not a React render context.

Set auth, validation, response content type, cache policy and cancellation for
the actual endpoint. Do not assume every Route Handler has Node.js APIs if the
project selected another runtime.

GET caching depends on the installed version and Cache Components mode.
It is uncached by default from 15; without Cache Components,
`dynamic = 'force-static'` opts it in. With Cache Components, GET can prerender
until request or uncached data access, and `use cache` belongs in a helper,
not the handler export/body. A request-time endpoint may still call a cached
read helper; do not cache its side effects. Non-GET methods run per request. Generated
`RouteContext<'/users/[id]'>` supplies the async params type.

For a streamed response, proxies and terminal errors matter after HTTP headers
are sent. Returning an async stream is not itself a durable job.

Read [Route Handlers](https://nextjs.org/docs/app/api-reference/file-conventions/route)
and the project's API conventions rather than copying a generic CRUD handler.
