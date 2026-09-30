# Streaming

`Runner.run_streamed(agent, input)` is not awaited; iterate
`result.stream_events()` to the end. Session writes, approval state, compaction
and `final_output` settle after the last visible token.

| `event.type` | Payload |
| --- | --- |
| `raw_response_event` | `event.data` is a Responses API event; text deltas are `ResponseTextDeltaEvent` (`openai.types.responses`), read `.delta` |
| `run_item_stream_event` | `event.name`: `message_output_created`, `tool_called`, `tool_output`, `handoff_requested`, `handoff_occured` (sic), `reasoning_item_created`, `mcp_approval_requested`, …; `event.item` holds the item |
| `agent_updated_stream_event` | `event.new_agent` after a handoff |

- Tripwires, `MaxTurnsExceeded` and provider failures raise from the `async for`,
  often after an HTTP 200 has been sent. Emit a terminal error in the UI
  protocol; keep provider and database details on the server.
- `result.cancel()` stops now; `result.cancel(mode="after_turn")` finishes the
  current turn first.
- A tool needing approval ends the stream with `result.interruptions` set;
  approve on `result.to_state()` and resume with `Runner.run_streamed(agent, state)`.
- Output guardrails run after completion and cannot withdraw sent deltas. When
  unvalidated text must not reach the user, buffer it or check earlier with a
  blocking input guardrail or a tool guardrail.

Test with `agents.testing.ScriptedModel`; `ModelStep.stream()` scripts exact
events. Official docs: [streaming](https://openai.github.io/openai-agents-python/streaming/).
