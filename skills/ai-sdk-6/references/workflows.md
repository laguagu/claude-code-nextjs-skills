# Orchestration choices

Fixed steps are ordinary application code; use a tool loop only when the model
must choose the next action. Official patterns (sequential, routing, parallel,
orchestrator-worker, evaluator-optimizer) are in `docs/03-agents/03-workflows.mdx`
or the [v6 workflow patterns](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-agents/03-workflows.mdx).

An LLM judge/evaluator loop needs a bounded stopping rule.

Durable execution (`WorkflowAgent` from `@ai-sdk/workflow`) is v7-only. Do not
silently upgrade the SDK to introduce it.
