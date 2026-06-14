# Debug Tricks

Tricks to speed up debugging Next.js applications.

## Next.js DevTools MCP (Dev Server)

Next.js 16+ ships a built-in MCP endpoint at `/_next/mcp` in the dev server for
AI-assisted debugging. **Requires Next.js 16 or above.**

### Recommended setup: `next-devtools-mcp`

The official, documented way is to add the `next-devtools-mcp` package to your
project's `.mcp.json`. It auto-discovers and forwards to the running dev server
(works across multiple instances/ports):

```json
// .mcp.json (project root)
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

Then `npm run dev` and your coding agent connects automatically.

Reference: https://nextjs.org/docs/app/guides/mcp

### Calling the raw endpoint directly (advanced)

You can also hit the underlying `/_next/mcp` endpoint yourself. This is not the
documented path but is useful for scripting.

**Important**: Find the actual port of the running Next.js dev server (check terminal output or `package.json` scripts). Don't assume port 3000.

The endpoint uses JSON-RPC 2.0 over HTTP POST:

```bash
curl -X POST http://localhost:<port>/_next/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "tools/call",
    "params": {
      "name": "<tool-name>",
      "arguments": {}
    }
  }'
```

### Available Tools

#### `get_errors`
Get current errors from dev server (build errors, runtime errors with source-mapped stacks):
```json
{ "name": "get_errors", "arguments": {} }
```

#### `get_routes`
Discover all routes by scanning filesystem:
```json
{ "name": "get_routes", "arguments": {} }
// Optional: { "name": "get_routes", "arguments": { "routerType": "app" } }
```
Returns: `{ "appRouter": ["/", "/api/users/[id]", ...], "pagesRouter": [...] }`

#### `get_project_metadata`
Get project path and dev server URL:
```json
{ "name": "get_project_metadata", "arguments": {} }
```
Returns: `{ "projectPath": "/path/to/project", "devServerUrl": "http://localhost:3000" }`

#### `get_page_metadata`
Get runtime metadata about current page render (requires active browser session):
```json
{ "name": "get_page_metadata", "arguments": {} }
```
Returns segment trie data showing layouts, boundaries, and page components.

#### `get_logs`
Get path to Next.js development log file:
```json
{ "name": "get_logs", "arguments": {} }
```
Returns path to `<distDir>/logs/next-development.log`

#### `get_server_action_by_id`
Locate a Server Action by ID:
```json
{ "name": "get_server_action_by_id", "arguments": { "actionId": "<action-id>" } }
```

### Example: Get Errors

```bash
curl -X POST http://localhost:<port>/_next/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":"1","method":"tools/call","params":{"name":"get_errors","arguments":{}}}'
```

## Rebuild Specific Routes (Next.js 16+)

Use `--debug-build-paths` to rebuild only specific routes instead of the entire app:

The `--debug-build-paths` option takes **file paths** (not route URLs), supports glob patterns, and uses `=` syntax:

```bash
# Build a specific route
next build --debug-build-paths="app/page.tsx"

# Include route group folders in the path
next build --debug-build-paths="app/(marketing)/about/page.tsx"

# Use glob patterns
next build --debug-build-paths="app/**/page.tsx"
next build --debug-build-paths="pages/*.tsx"
```

Use this to:
- Quickly verify a build fix without full rebuild
- Debug static generation issues for specific pages
- Iterate faster on build errors
