---
name: go
description: Opens the running app in a browser and verifies recent UI changes actually work. Use whenever the user wants a quick smoke test or sanity check of recent work, or says "go", "open in browser", "check in browser", "test your work", "make sure it works", "smoke test", "verify", "did it actually work", "make sure the form/page works", "check the form submits", "works on mobile" — even when they don't explicitly ask for browser testing. Also activates implicitly when the user appends "...and make sure it works" to a UI request. Skips design critique; for that, use go-ui.
argument-hint: "[url or route]"
---

# /go — Quick browser smoke test

Verify recent UI changes by actually opening the app in a browser. Don't trust that code compiles — trust what the page renders.

## Workflow

1. **Make sure the dev server is running.** If not, start it (`bun dev` or whatever the project uses). Ask the user for the URL only if it's not obvious from the project.

2. **Open the browser.** Use whatever browser tool is available — Chrome extension, Playwright MCP, next-devtools, whichever the agent can reach. If nothing is available, report that and stop.

3. **Test what makes sense for the change.** Pick the flows that exercise what you just touched. Three things are easy to forget — make sure they happen:
   - **Functional verification** — did the page actually return what was expected? Searching for "X" should show results containing X, not just render without errors.
   - **Mobile viewport** — switch to ~375 px and look for layout breakage. Desktop view hides most responsive bugs.
   - **Console and network** — open devtools. Errors and 4xx/5xx are silent killers.

4. **Report back in three buckets**:
   - **Works:** what was verified
   - **Broken:** concrete failures that need fixing
   - **Suspicious:** anything that smells off but you're not sure

5. **Fix loop.** If something is broken, fix it → reload → verify in the browser again. Stop after 3 iterations without progress and ask for direction rather than thrashing.

## Gotchas

- Next.js HMR sometimes silently keeps stale modules. If a change should be visible but isn't, force a hard reload.
- React Server Component errors land in the **server** terminal, not the browser console. Check both.
- On Windows, `localhost` occasionally resolves to IPv6 and hangs. Try `127.0.0.1` if `localhost` won't load.
- The agent's screenshot is one frame in time — if something is animated or async, take a second look after the loading state settles.
- Don't deploy to production as part of `/go`. Stay on the local dev server unless the user explicitly asks otherwise.
