# Route Handler contracts

A `route.ts` owns HTTP handling at its route; it cannot coexist with a
`page.tsx` for that same segment. It is not a React render context.

Set auth, validation, response content type, cache policy and cancellation for
the actual endpoint. Do not assume every Route Handler has Node.js APIs if the
project selected another runtime.

GET caching behavior depends on installed Next.js and Cache Components mode.
A request-time endpoint may still call a suitable cached read helper.
Non-GET side effects must not be cached as results by accident.

For a streamed response, proxies and terminal errors matter after HTTP headers
are sent. Returning an async stream is not itself a durable job.

Read [Route Handlers](https://nextjs.org/docs/app/api-reference/file-conventions/route)
and the project's API conventions rather than copying a generic CRUD handler.
