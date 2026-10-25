# Runtime selection

Keep the project's supported runtime. Node.js is the default.
From 16.3, `export const runtime = 'edge'` in page/layout/route files is deprecated
(build warning, `/docs/messages/edge-runtime-deprecated`): do not add it;
remove it when migration is in scope.
`export const preferredRegion` is deprecated from 16.3 as well
(`/docs/messages/preferred-region-deprecated`): do not add it. Set function
regions in the host's configuration (on Vercel, project settings or `regions`
in `vercel.json`/`vercel.ts`).

Runtime location is hosting-specific. An Edge label alone does not prove lower
latency. Cache Components and Proxy have their own runtime restrictions;
inspect installed configuration before changing them.

Read [Edge runtime](https://nextjs.org/docs/app/api-reference/edge)
and the deployment adapter's current support.
