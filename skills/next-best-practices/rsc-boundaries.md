# Server/client boundaries

`use client` marks a module boundary, including its imports. Put it around
interactive/browser work, while keeping secrets and server dependencies out.
A provider wrapper may be a valid broader boundary; imported children passed
from a Server Component can remain server-rendered.

Client components cannot themselves be async functions. Moving logic to a client
file also does not eliminate server prerendering or make browser globals safe
during initial render.

Props crossing Server → Client use React serialization, which is broader than
JSON. Dates, Maps, Sets, supported promises/JSX and Server Functions have
documented forms. Arbitrary class instances and ordinary server closures do not.
Callbacks inside an already-client subtree are legal.

A type-only import can share server-derived contracts without importing runtime
execution. Authorize Server Functions at their entry point; being passed as a
prop does not make them private.

Read `01-getting-started/05-server-and-client-components.md` and
`02-guides/server-and-client-boundary.md`. The complete type list is in
the React docs (`https://react.dev/reference/rsc/use-client#serializable-types`).
