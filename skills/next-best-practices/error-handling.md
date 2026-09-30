# Error and control-flow boundaries

Model expected errors as safe application outcomes. Keep internal diagnostics
out of public responses. Unexpected render errors go to the appropriate
segment/root boundary.

`error.tsx` is a client boundary; it does not catch errors from the layout in
the same segment. `global-error.tsx` replaces the root layout and needs its
own html/body. Check installed behavior before changing reset/retry logic.

`redirect`, `notFound` and related navigation helpers throw framework signals.
Call them outside ordinary catch blocks or use the installed supported rethrow
helper. Redirect status can differ in Server Actions, so do not assign one
status to every context.

Auth-interrupt helpers may be experimental/version-gated. Check configuration
and current support instead of enabling a flag from a stale example.

Read [error handling](https://nextjs.org/docs/app/getting-started/error-handling)
and the affected helper's installed reference.
