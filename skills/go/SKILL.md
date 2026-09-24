---
name: go
description: Opens the running app in a browser and verifies that recent UI changes actually work. Use for any quick smoke test of recent work — "go", "test in browser", "check in browser", "make sure it works", "verify it works", "did it work", "works on mobile" — including when the user appends "...and make sure it works" to a UI request. For design critique, use go-ui or web-design-guidelines.
---

# /go — Browser check

Verify the work in a real browser instead of trusting that it compiles. Use whichever browser tooling is available and fits the check best.

Easy to miss:
- **Functional result** — the page does what was intended, not just renders. A search for "X" shows results about X.
- **Console and network** — JS errors and failed requests (4xx/5xx) break things silently.

If login is needed, look for test credentials in the project's env files or secrets manager. If something is broken, fix and verify again; when the same issue keeps failing, ask for direction.
