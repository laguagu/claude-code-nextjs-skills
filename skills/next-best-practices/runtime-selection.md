# Runtime selection

Keep the project's supported runtime. Node.js is the usual default and supports
native/server dependencies; choosing Edge requires compatible packages and a
real deployment requirement.

Runtime location is hosting-specific. An Edge label alone does not prove lower
latency. Cache Components and Proxy have their own runtime restrictions;
inspect installed configuration before changing them.

Read [Edge runtime](https://nextjs.org/docs/app/api-reference/edge)
and the deployment adapter's current support.
