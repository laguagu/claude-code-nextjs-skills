---
name: go
description: Opens the running app in a browser and verifies recent UI changes actually work. Use whenever the user wants a quick smoke test or sanity check of recent work, or says "go", "open in browser", "check in browser", "test your work", "make sure it works", "smoke test", "verify", "did it actually work", "make sure the form/page works", "check the form submits", "works on mobile" — even when they don't explicitly ask for browser testing. Also activates implicitly when the user appends "...and make sure it works" to a UI request. Skips design critique; for that, use go-ui.
argument-hint: "[url or route]"
---

# /go — Browser check

Verify your work in the browser instead of trusting that code compiles. Use whatever browser tools the environment offers (Chrome extension, next-devtools MCP, chrome-devtools MCP, Playwright — whichever is reachable). If `chrome-devtools` MCP is available and you need console errors, network status, or computed styles to confirm the fix, prefer it over a blind reload. If login is needed, credentials usually live in `.env.local` or the project's secrets manager.

Two things are easy to miss:
- **Functional verification** — did the page actually return what was expected? Searching for "X" should show results containing X, not just render without errors.
- **Console and network** — JS errors and 4xx/5xx are silent killers.

If something is broken, fix → reload → verify again. Don't thrash on the same issue — ask for direction instead.
