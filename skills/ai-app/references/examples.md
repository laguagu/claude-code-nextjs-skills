# Official examples

Find the feature in the [AI SDK documentation](https://ai-sdk.dev/docs) or the
[Vercel AI examples](https://github.com/vercel/ai/tree/main/examples), then read
only the relevant implementation. Repository main may target a newer major;
use an installed-package reference or matching tag for an older app.

Use `ai-sdk-6` or `ai-sdk-7` for version boundaries and `ai-elements` for
installed component props. Provider-specific tools, approvals and media handling
need the matching provider package documentation too.

Examples establish API usage. Adapt authentication, authorization, retention,
error handling and persistence to the app's actual requirements. Do not import
demo model IDs, fake tool results or an entire feature list into a real app.
