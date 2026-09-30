# History ownership and sessions

Choose one conversation-history owner: application-managed input, an SDK session
or provider-managed Responses conversation state. Combining owners can duplicate
history or replay already-executed operations.

Use the installed session implementations for the actual storage/runtime.
SQLite fits local/single-instance storage; a supported SQL/Redis store may fit
distributed persistence. Session IDs need server-side ownership checks and
appropriate tenant scoping. A database row is not automatically durable workflow
state.

Persist replay-valid SDK input/items, including required tool-call/result and
reasoning context. Compaction, branching and encryption wrappers have their own
semantics; read the relevant adapter before introducing them.

An encrypted session does not encrypt provider requests or trace uploads.
Define deletion/retention across application history, hosted conversation state,
logs and backups when those are in scope.

Read [sessions](https://openai.github.io/openai-agents-python/sessions/)
and [running agents](https://openai.github.io/openai-agents-python/running_agents/)
for compatible history/resume examples.
