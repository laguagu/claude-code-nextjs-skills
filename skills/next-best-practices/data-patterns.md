# Data and action boundaries

Read directly in Server Components when that fits rendering; avoid calling the
app's own Route Handler just to wrap the same server-side data access. Use
client fetching where the interaction needs independent/refreshed data.

Server Actions fit UI mutations. They use POST and are externally reachable
endpoints: `use server` does not make a function private. Authenticate,
authorize and validate on every call. Reading through an Action is possible,
but can serialize client calls and is not a general read API.

Route Handlers fit external APIs, webhooks, downloads and independent HTTP
behavior. UI mutations may use them too when that contract is appropriate;
neither boundary prohibits the other mechanically.

Caching depends on actual options/configuration, not merely the location of a
read. Invalidate affected cached data after a committed write; pick immediate
read-your-writes or stale-while-revalidate deliberately.

Parallelize genuinely independent reads, and stream meaningful sections when
latency requires it. Preserve data dependencies and failure semantics.

Read `02-guides/data-security.md`, `01-getting-started/06-fetching-data.md`
and `01-getting-started/07-mutating-data.md`; without Cache Components,
`02-guides/caching-without-cache-components.md`.
