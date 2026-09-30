# AI SDK 6 MCP integration

Use `createMCPClient` from `@ai-sdk/mcp` (install `@ai-v6`) with
`transport: { type: 'http' | 'sse', url, headers?, authProvider? }`; stdio
(`Experimental_StdioMCPTransport` from `@ai-sdk/mcp/mcp-stdio`) is for local
servers only. V6 HTTP/SSE transports follow redirects by default; set
`redirect: 'error'` unless the server is trusted (v7 made that the default).

MCP discovery is not an authorization decision: expose only tools the app
allows, and keep server URLs under application policy, not user input.

Keep the MCP client alive for the whole tool loop. For non-streaming work, close
it in cleanup; for streaming, close it after completion/error/cancellation, not
immediately after returning the response.

Check provider/SDK support for resources, prompts and elicitation separately
from ordinary tool discovery. Set explicit bounds where remote calls can stall.

Read `docs/03-ai-sdk-core/16-mcp-tools.mdx` (the package ships no docs; its
types are in `@ai-sdk/mcp`) or
[v6 MCP tools](https://github.com/vercel/ai/blob/ai%406.0.297/content/docs/03-ai-sdk-core/16-mcp-tools.mdx).
