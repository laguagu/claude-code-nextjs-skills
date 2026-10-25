---
name: go
description: Opens the running app in a browser and verifies that recent UI changes actually work. Use for any quick smoke test of recent work — "go", "test in browser", "check in browser", "make sure it works", "verify it works", "did it work", "works on mobile" — including when the user appends "...and make sure it works" to a UI request. For design critique, use web-design-guidelines.
---

# /go — Browser check

Verify the work in a real browser instead of trusting that it compiles. Use whichever browser tooling is available and fits the check best.

Easy to miss:
- **Functional result** — the page does what was intended, not just renders. A search for "X" shows results about X.
- **Console and network** — JS errors and failed requests (4xx/5xx) break things silently.

A login wall is not a reason to stop. Prefer a browser where the user is already signed in; that also covers SSO, OAuth and MFA. Otherwise use a test account from the project's seed, fixture or example config, or the user's secrets manager. Do not open, print or search an env file for credentials: if a test login exists only there, load it inside the script that signs in (for example a Playwright script reading process.env), never through chat or tool arguments. On a deployed site a signed-in session is the user's real account, so check without changing data.

If something is broken, fix and verify again; when the same issue keeps failing, ask for direction.
