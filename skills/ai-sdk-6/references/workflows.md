# Orchestration choices

Use the simplest execution model that meets the product contract. Fixed steps
can be ordinary application code; independent work can run concurrently. Use a
tool loop when the model must choose the next action.

A routing, worker or evaluator stage earns its place through a task requirement
or measured improvement. It adds model calls, latency and failure paths; an
LLM judge needs a bounded stopping rule and criteria the supplied evidence can
establish.

These v6 application patterns do not provide the durable `WorkflowAgent`
runtime added through a separate package in v7. Do not silently upgrade the
SDK to introduce it.

Use the installed agent docs or
[v6 workflow patterns](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-agents/03-workflows.mdx) for a
matching official example.
