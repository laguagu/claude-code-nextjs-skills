# MCP (Model Context Protocol) Reference

MCP is an open standard for connecting Claude to external tools and data sources.

## Architecture

- **MCP Servers:** Expose tools and data
- **MCP Clients:** Claude Code connects to servers
- **Protocol:** Standardized communication

## Configuration

### Config File Locations

- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
- **Project-level:** `.mcp.json` or `.claude/settings.local.json`

### Basic Format

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@package/server-name", "arg1"],
      "env": {
        "API_KEY": "your-key"
      }
    }
  }
}
```

## Example Configurations

### Filesystem Server
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/username/Documents",
        "/Users/username/Projects"
      ]
    }
  }
}
```

### GitHub Server
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx"
      }
    }
  }
}
```

### PostgreSQL Server
```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost/db"
      }
    }
  }
}
```

### Sequential Thinking
```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

## CLI Commands

```bash
# Add a server
claude mcp add github --scope user

# List servers
claude mcp list

# Remove a server
claude mcp remove github
```

## Referencing MCP Tools in Skills

Use fully qualified tool names: `ServerName:tool_name`

```markdown
Use the GitHub:create_issue tool to create issues.
Use the filesystem:read_file tool to read files.
```

## allowed-tools with MCP

Restrict MCP tool access in skill frontmatter:

```yaml
---
name: github-skill
description: Works with GitHub repos
allowed-tools:
  - github
  - Read
  - Write
---
```

## Popular MCP Servers

| Server | Purpose |
|--------|---------|
| filesystem | Read/write local files |
| github | GitHub API operations |
| postgres | PostgreSQL queries |
| sqlite | SQLite database |
| slack | Slack messaging |
| google-drive | Google Drive access |
| sequential-thinking | Step-by-step reasoning |
| perplexity | Web search |

## Dynamic Updates

MCP servers support `list_changed` notifications - they can update available tools without reconnection.

## Security

- Only install MCP servers from trusted sources
- Review server permissions before enabling
- Use environment variables for secrets
- Anthropic has not verified third-party servers
