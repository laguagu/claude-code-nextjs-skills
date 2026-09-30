# Follow-up suggestions

Add suggestions when they help the user take a plausible next step. They are
optional; an answer does not need a fresh chip row every time. Existing tool
choices or unanswered options often work better than an extra model call.

When the assistant asks for a choice or confirmation, suggest valid replies to
that request. Offer new follow-up questions after a completed answer.

Ground suggestions in the available answer, source records and supported
actions. Preserve names and options accurately, and do not invent categories
or promise unavailable data. A suggested question and a button that executes
a side effect need distinct behavior; execution still requires authorization
and any required approval.

If a model generates suggestions, use a small validated output schema (e.g.
`generateText` with `output: Output.array({ element: z.string() })`) and
choose a supported model from measured quality/cost/latency. Tie the request
to the conversation and answer IDs, cancel or discard stale results after a
new turn, and allow generation failure to leave no suggestions.

Keep labels readable at the actual viewport and language. Wrap or lay them out
without clipping; fixed word counts and mandatory single-line chips do not
generalize. AI Elements `Suggestions` is one non-wrapping row (horizontal
`ScrollArea`, hidden scrollbar); edit the generated `suggestion.tsx` to wrap.
Suggestions should complement the answer instead of duplicating it or
displacing the composer.

Verify unavailable entities, incomplete answers, conversation switching,
screen-reader names and narrow layouts.
