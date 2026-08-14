# Follow-up Suggestions

Generate contextual follow-up chips after each assistant response. Improves
engagement by guiding users toward relevant next steps.

## Contents

- [API route](#api-route)
- [Match the chip to how the answer ended](#match-the-chip-to-how-the-answer-ended)
- [Generation logic: generateText + Output.object](#generation-logic-generatetext--outputobject)
- [Client integration](#client-integration)
- [Layout: wrap, never a nowrap scroller](#layout-wrap-never-a-nowrap-scroller)
- [Gotchas](#gotchas)

## API route

```ts
// app/api/suggestions/route.ts
import { NextResponse } from "next/server";
import { z } from "zod";
import { generateSuggestions } from "@/lib/ai/generate-suggestions";

export const maxDuration = 30;

const requestSchema = z.object({
  question: z.string().min(1).max(5000),
  answer: z.string().min(1).max(10000),
});

export async function POST(request: Request) {
  try {
    const parsed = requestSchema.safeParse(await request.json());
    if (!parsed.success) {
      return NextResponse.json({ error: "Invalid input" }, { status: 400 });
    }

    const suggestions = await generateSuggestions(parsed.data.question, parsed.data.answer);
    return NextResponse.json({ suggestions });
  } catch (error) {
    console.error("Error generating suggestions:", error);
    return NextResponse.json({ error: "Failed to generate suggestions" }, { status: 500 });
  }
}
```

## Match the chip to how the answer ended

This is the part that makes suggestions feel designed rather than bolted on, and
it is the part a generic "suggest 2-3 follow-up questions" prompt gets wrong.

A single prompt produces a new *question* every time — including right after the
bot itself asked the user something. The user is then offered three questions to
ask instead of the one answer they were supposed to give. Classify the tail of
the answer first, then prompt for the shape that fits:

| Mode | Cue in the last 1–2 sentences | What the chip must be |
|---|---|---|
| `pick-from-options` | an enumerated list (`X, Y, or Z`, `X / Y / Z`) **and** an ask or an offer | the user's **answer**, pulled from the listed options: 1–3 words, no question mark ("Strategy", "Technical / PoC") |
| `accept-or-decline-offer` | the bot proposed one specific next step ("If you want, I can also show…") | first chip = a clear **acceptance naming what was offered** ("Yes, show testing services"); then 1–2 chips redirecting to a different topic |
| `open` | none of the above — a complete answer | open follow-up questions on related topics |

Detection is a small function over the tail, not an LLM call:

```ts
function detectFollowUpMode(answer: string): FollowUpMode {
  // The cue is almost always in the last 1-2 sentences; checking earlier ones
  // risks firing on a bullet list above the closer.
  const tail = answer.trim().split(/(?<=[.!?])\s+/).slice(-2).join(" ");

  // Don't require a literal "?" — the bot signals an ask with phrases too
  // ("Tell me whether…", "I can also…"). Match in every language you support.
  const explicitAsk = /\?/.test(tail) || /\b(tell me|let me know|which one|would you like)\b/i.test(tail);
  const offersNextStep = /\b(if you (would |'d )?(like|want)|i can (also )?(show|list|find)|shall i|want me to)\b/i.test(tail);
  const listsOptions =
    /\w[\w\s\-]*?,\s*\w[\w\s\-]*?,\s*\w/.test(tail) ||   // "X, Y, Z"
    /\w\s+\/\s+\w[\w\s\-]*?\s+\/\s+\w/.test(tail) ||     // "X / Y / Z" (2+ slashes,
                                                          // so "testing / piloting
                                                          // services" isn't a list)
    /,\s*or\s+\w/i.test(tail);                            // Oxford comma

  if (listsOptions && (explicitAsk || offersNextStep)) return { kind: "pick-from-options" };
  if (offersNextStep) return { kind: "accept-or-decline-offer" };
  return { kind: "open" };
}
```

Then `buildPrompt(mode, question, answer)` returns a different instruction block
per mode. The `pick-from-options` block is the one worth being strict in: *"Each
chip is the user's reply, NOT a new question. 1-3 words. No question marks. Pull
the labels straight from the options the assistant offered. Do not invent options
the assistant didn't list."*

## Generation logic: generateText + Output.object

Use a cheap, fast model — suggestions are non-critical and latency matters more
than quality. Read the current model id from the provider's live catalog and put
it behind one constant (`nanoModel`); do not hardcode a version in a component.

```ts
// lib/ai/generate-suggestions.ts
import { generateText, Output } from "ai";
import { z } from "zod";
import { nanoModel } from "./model";

const suggestionsSchema = z.object({
  questions: z.array(z.string()).max(4)
    .describe("Follow-up clicks the user might send next"),
});

export async function generateSuggestions(
  question: string,
  answer: string,
): Promise<string[]> {
  const mode = detectFollowUpMode(answer);
  try {
    const { output } = await generateText({
      model: nanoModel,
      output: Output.object({ schema: suggestionsSchema }),
      prompt: buildPrompt(mode, question, answer),
    });
    return output?.questions ?? [];
  } catch (error) {
    if (process.env.NODE_ENV !== "production") {
      console.error("[generateSuggestions]", error);
    }
    return []; // Fail silently — suggestions are not critical
  }
}
```

Rules to carry into every mode's prompt: under ~10 words, no leading "Can you…"
filler, match the language of the **user's** message, never repeat the user's
previous question.

<a id="grounding"></a>
### Grounding (why an anti-invention rule matters here)

The nano model sees only the last Q/A pair — no tool results — and is tuned for
speed, which makes it more prone to confident hallucination than the main chat
model. On a catalog-style chatbot it'll happily propose follow-ups referencing
component names that don't exist. Add:

```
NEVER invent product, component, parser, or package names. You may ONLY
reference names that appear verbatim in the assistant's answer above. If you are
not sure a name is real, use a generic phrase instead (e.g. "the right PDF parser
for scanned docs" rather than a specific name).
```

For stronger guarantees, post-filter and reject any suggestion naming an entity
that isn't in the last tool-result payload.

## Client integration

### Fetch after each response

Call the suggestions API when the stream finishes. Store results in Zustand or
local state; clear them when the user sends a new message.

```ts
const { messages, sendMessage } = useChat({
  transport: new DefaultChatTransport({ api: "/api/chat" }),
  onFinish: async ({ message, messages }) => {
    const lastUserMsg = [...messages].reverse().find(m => m.role === "user");
    const question = getTextFromParts(lastUserMsg?.parts);
    const answer = getTextFromParts(message.parts);
    if (!question || !answer) return;
    try {
      const res = await fetch("/api/suggestions", {
        method: "POST",
        body: JSON.stringify({ question, answer }),
      });
      setSuggestions((await res.json()).suggestions);
    } catch {
      // Fail silently
    }
  },
});
```

### Display

`Suggestion` takes the text as a **`suggestion` prop** and hands it back to
`onClick` — it is not a plain button whose child is the label:

```tsx
{suggestions.map(text => (
  <Suggestion key={text} suggestion={text} onClick={handleSuggestionClick} />
))}

const handleSuggestionClick = (text: string) => {
  setSuggestions([]);   // clear before sending — stale chips are confusing
  sendMessage({ text });
};
```

## Layout: wrap, never a nowrap scroller

Lay the chips out in a **wrapping flex container** with `whitespace-normal`:

```tsx
<div className="flex flex-wrap items-start gap-1.5">
  {/* chip: h-auto max-w-full whitespace-normal text-left justify-start */}
</div>
```

A horizontal scroller with `whitespace-nowrap` chips is the obvious-looking
choice and it is wrong for this content. The three modes above produce wildly
different lengths — a one-word answer chip next to a ten-word open question — and
in a 400px-wide widget the long ones get cut off at the scroller's fade
gradient. The user cannot read a suggestion without dragging it into view, which
is strictly worse than the chip not being there. Wrapping handles both shapes:
short chips share a row, long ones take a row and wrap inside. It also deletes
the fade overlays, the arrow buttons and the `ResizeObserver` that a scroller
needs — including two focusable-but-invisible arrow buttons in the tab order.

If the surface is genuinely wide (≥ 768px), a 2-column grid with
`sm:whitespace-normal` is a reasonable alternative. Nowrap is only safe on chips
you author yourself and can keep short.

**Loading state:** render skeleton pills in the same shape as the result, not a
spinner with "Loading suggestions…". Text that is later replaced by chips shifts
the layout at exactly the moment the user is reading. Keep the text as an
`sr-only` `aria-live` region so screen readers still get it.

## Gotchas

- Use a cheap model — suggestions run after every response, cost adds up fast
- Fail silently — never block the chat UI if suggestions fail
- Clear on send — stale suggestions from a previous turn are confusing
- Language matching — instruct the model to match the user's language
- Key chips by their text, not by array index
