# Streaming contracts

`Runner.run_streamed` returns a streamed result. Consume `stream_events()`
through completion to establish final output, usage and terminal failure.
Raw provider deltas, run items and agent changes are distinct event shapes:
`raw_response_event` (`event.data`), `run_item_stream_event` (`event.item`)
and `agent_updated_stream_event` (`event.new_agent`). The handoff-completed
event name is spelled `handoff_occured`.

`result.cancel()` cancels immediately; `result.cancel(mode="after_turn")`
finishes the current turn. Approval pauses end with `result.interruptions`;
resume the approved/rejected state with `Runner.run_streamed(original_agent, state)`.

Choose the UI protocol explicitly. A stream already opened with a successful
HTTP status can still emit a terminal error. Handle cancellation and safe public
errors; keep provider/DB diagnostics on the server.

Input guardrails can run in parallel, and output guardrails run after agent
completion. Already-sent deltas or completed side effects cannot be withdrawn.
If the product must withhold unvalidated content, buffer it or use the matching
blocking/tool boundary rather than claiming output guardrails prevent display.

Read [streaming docs](https://openai.github.io/openai-agents-python/streaming/)
and [guardrails](https://openai.github.io/openai-agents-python/guardrails/) for
event and persistence behavior in the installed version. Verify tool events,
partial output, tripwires and disconnects alongside successful text.
