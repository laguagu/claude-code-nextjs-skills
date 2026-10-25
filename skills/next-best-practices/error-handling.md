# Error and control-flow boundaries

Model expected errors as safe application outcomes. Keep internal diagnostics
out of public responses. Unexpected render errors go to the appropriate
segment/root boundary.

`error.tsx` is a client boundary; it does not catch errors from the layout in
the same segment. `global-error.tsx` replaces the root layout and needs its
own html/body, styles and other required dependencies. It does not inherit the
root layout's global styles. `retry()` re-fetches and re-renders the segment
(stable in 16.3; `unstable_retry` in 16.2), while `reset()` only clears the
error state and re-renders without re-fetching. Check the installed contract.

`redirect`, `notFound` and related navigation helpers throw framework signals.
Call them outside ordinary catch blocks or call `unstable_rethrow(error)`
(`next/navigation`) first in the catch. For a component-level boundary,
`catchError` (`next/error`; stable in 16.3, `unstable_catchError` in 16.2)
lets those signals through. Redirect status can differ in Server Actions, so
do not assign one status to every context.

`forbidden()`/`unauthorized()` and their files are still experimental and need
`experimental.authInterrupts`. Check current support instead of enabling a
flag from a stale example.

Read [error handling](https://nextjs.org/docs/app/getting-started/error-handling)
and the affected helper's installed reference.
