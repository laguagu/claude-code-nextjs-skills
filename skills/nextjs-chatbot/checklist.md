# Building a chatbot

Agree the supported task, audience, source of truth, data policy and quality/
latency budget. Inspect the existing application before choosing dependencies.

1. Resolve installed SDK/provider versions and select a supported model from
   the current provider configuration. Keep model selection server-controlled.
2. Connect the smallest working chat path using version-matched transport and
   stream helpers. Validate requests and redact public errors.
3. Add only required tools. Enforce user/tenant permissions and side-effect
   idempotency inside the server execution path.
4. Add approval when the product calls for it; verify approve, deny, tampered
   replay and duplicate submission.
5. Add persistence if history must survive reload. Establish stable IDs,
   ownership, retention, disconnect behavior and deletion coverage.
6. Build the readable chat surface: Markdown, relevant results/sources, focus,
   scroll anchoring and accessible controls. Add optional message actions or
   suggestions only when useful.
7. Exercise restored second turns, incomplete tool states and failures with
   the actual provider and deployment path. Use scoped model/retrieval evals
   when changing model behavior or grounding.

See [testing.md](testing.md) for verification scope and [SKILL.md](SKILL.md) for
the feature references. Installation commands, database migrations and MCP
configuration belong to the project's actual stack, not a mandatory scaffold.
