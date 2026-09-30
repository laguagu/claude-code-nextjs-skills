# Error and control-flow boundaries

Model expected errors as safe application outcomes. Keep internal diagnostics
out of public responses. Unexpected render errors go to the appropriate
segment/root boundary.

`error.tsx` is a client boundary; it does not catch errors from the layout in
the same segment. `global-error.tsx` replaces the root layout, needs its own
html/body and gets no global styles or metadata export. From 16.3 the boundary
receives `retry()` (re-fetch and re-render; `unstable_retry` in 16.2); `reset()`
only clears state. `catchError` from `next/error` builds component-level
boundaries (16.3; `unstable_catchError` in 16.2).

`redirect`, `permanentRedirect` and `notFound` throw framework signals. Call
them outside `try`, or call `unstable_rethrow(err)` from `next/navigation` first
in the `catch`. In a Server Action `redirect` defaults to `push` and answers a
no-JS form post with 303; elsewhere it is 307.

`forbidden()`/`unauthorized()` require `experimental.authInterrupts`.

Read `01-getting-started/10-error-handling.md` and
`03-api-reference/03-file-conventions/error.md`.
