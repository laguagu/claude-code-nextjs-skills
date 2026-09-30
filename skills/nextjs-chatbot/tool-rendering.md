# Tool result UI

Infer message/tool types from the agent or the installed SDK. Branch on the
typed discriminant and state so partial input is not treated as a completed
result. Dynamic tools require their own runtime validation; avoid loose casts
that claim unknown output is a trusted application record.

Give each useful result a renderer appropriate to its content. A generic tool
accordion can be sufficient for diagnostics; product users need the answer,
action or result they can use. Avoid printing internal names, JSON, database
errors or duplicate summaries when a card already communicates the result.

Handle loading, approval, denial, success and safe failure. A result can be
empty or false-valued, so do not use output truthiness as proof of success.
Stable tool-call IDs keep updates associated with the same operation.

Derive the final answer/action visibility from the overall turn status.
Intermediate gaps between tools do not mean the turn finished. Keep old
results readable during later generation and preserve scroll/focus.

Validate tool data on the server and at external boundaries. Sanitize rendered
Markdown/HTML and apply application policy to links or attachments; model or
tool output is not automatically safe DOM content.

See [HITL](hitl.md), `ai-elements` for existing components and the
[UI tool guide](https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-tool-usage) for the
version-matched state and continuation contract.
