# AI SDK 6 MCP integration

Use the compatible `@ai-sdk/mcp` client. Read installed transport and schema
types before wiring a remote server; production HTTP and SSE have different
lifecycle behavior from a local stdio process.

Discover only the tools the app is authorized to expose. Validate tool schemas,
credential handling and server identity; MCP discovery is not an authorization
decision. Keep remote endpoints under application policy rather than accepting
arbitrary user URLs.

Keep the MCP client alive for the whole tool loop. For non-streaming work, close
it in cleanup; for streaming, close it after completion/error/cancellation, not
immediately after returning the response.

Check provider/SDK support for resources, prompts and elicitation separately
from ordinary tool discovery. Set explicit bounds where remote calls can stall.

Read [v6 MCP tools](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-ai-sdk-core/16-mcp-tools.mdx) and
the installed `@ai-sdk/mcp` docs/source.
