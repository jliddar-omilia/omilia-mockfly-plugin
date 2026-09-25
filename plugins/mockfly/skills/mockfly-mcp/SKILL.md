---
name: mockfly-mcp
description: >-
  Connect and troubleshoot the Mockfly MCP server in Claude Code: install,
  authentication (account key vs project key), the tool catalog, and common
  setup mistakes. Use when Mockfly MCP tools are unavailable, a call returns
  401/403/429, or this is the first time connecting Claude Code to Mockfly.
  Trigger terms: Mockfly MCP, mockfly-mcp-client, MOCKFLY_API_KEY,
  MOCKFLY_ACCOUNT_API_KEY, mock API setup.
license: MIT
compatibility: mockfly-mcp-client (npm), official Mockfly MCP server
metadata:
  author: Omilia — community integration, not officially maintained by Mockfly
  version: "0.1.0"
  category: operations
---

# Mockfly MCP Server

Mockfly publishes an official MCP server, `mockfly-mcp-client`, that lets an
AI coding tool manage Mockfly projects, mock endpoints, and mock responses
directly. This skill covers **setup**, **authentication**, the **tool
catalog**, and **troubleshooting**.

The **mockfly-projects** skill covers day-to-day usage of these tools once
connected. The **mockfly-cli** skill covers the separate offline CLI for
serving mocks locally without the cloud API.

## When to Use

- Mockfly MCP tools are unavailable or `claude mcp list` doesn't show `mockfly`
- First-time Mockfly setup for Claude Code
- A tool call returns 401 (bad key), 403 (wrong key type for the operation),
  or 429 (free-plan limit exceeded)
- Deciding whether an operation needs the account key or the project key

## Connection Details

| Property | Value |
|---|---|
| Package | `mockfly-mcp-client` (npm, published by the Mockfly team) |
| Transport | stdio, launched via `npx -y mockfly-mcp-client` |
| Auth | Two API keys, at least one required — see below |
| Docs | `https://mockfly.dev/docs/mockfly-mcp-client/` |
| Source | Closed source — npm-distributed compiled bundle, no public repo. You can configure it, not fork it. |

**Note on Claude Code support:** Mockfly's own docs list Claude Desktop and
Antigravity as supported clients, not Claude Code by name. It uses the
standard MCP stdio + `mcpServers` JSON shape Claude Code also reads, so it
should register the same way — but treat this as unverified until confirmed
with `claude mcp list` / `/mcp` after setup, per the docs above.

## Setup

### Via this plugin (recommended)

If the `mockfly` plugin from this marketplace is installed, run `/config`
and fill in **Mockfly account API key** and **Mockfly project API key**.
Both are stored in Claude Code's secure credential store (not plaintext
settings), and substituted into the bundled MCP server automatically. No
manual JSON editing needed.

### Manual setup (no plugin)

1. Get keys from the Mockfly dashboard:
   - Account key: `app.mockfly.dev/api-keys`
   - Project key: the project's settings page
2. Register the server:

```bash
claude mcp add --env MOCKFLY_ACCOUNT_API_KEY=<account_key> \
  --env MOCKFLY_API_KEY=<project_key> \
  --transport stdio mockfly --scope user \
  -- npx -y mockfly-mcp-client
```

3. Verify with `claude mcp list` or `/mcp` inside a session.

## Authentication

Two independent keys, matching Mockfly's public REST API:

| Key | Env var | Scope | Used for |
|---|---|---|---|
| Account API key | `MOCKFLY_ACCOUNT_API_KEY` | Account | `create_project`, `import_project`, `update_project`, `delete_project` |
| Project API key | `MOCKFLY_API_KEY` | One project | Endpoint, response, and rule operations |

Set both if you'll do both kinds of work. A key sent to the wrong operation
returns 403, not a silent failure.

## Tool Catalog

### Project management (account key)

| Tool | Purpose |
|---|---|
| `create_project` | Create an empty project |
| `import_project` | Create a project pre-populated from OpenAPI, Postman, or HAR |
| `update_project` | Rename / retag a project |
| `delete_project` | Delete a project |

### Endpoint and response management (project key)

| Tool | Purpose |
|---|---|
| `get_endpoints` | List a project's endpoints |
| `get_endpoint_detail` | Get one endpoint with its responses expanded |
| `create_endpoint` / `edit_endpoint` / `delete_endpoint` | Manage endpoints |
| `create_response` / `edit_response` / `duplicate_response` / `delete_response` | Manage mock responses on an endpoint |
| `modify_rules` | Set conditional rules that pick a response based on the request |

See `mockfly-projects` for how these map to plan limits and common workflows.

## Common Mistakes

| Mistake | Fix |
|---|---|
| 401 on any call | Key missing, expired, or truncated when pasted into `/config` |
| 403 on a project-level call | You supplied the project key, not the account key (or vice versa) |
| 429 on create | Free plan: 1 project as admin, 4 endpoints/project, 2 responses/endpoint |
| Tools not appearing | Restart Claude Code / start a new session after enabling the plugin or running `claude mcp add` |
| Assuming Claude Desktop-only features work identically | Mockfly's docs don't name Claude Code explicitly — re-verify after any `mockfly-mcp-client` version bump |

## Troubleshooting

See `references/troubleshooting.md` for connection and auth failure detail.

## Related Skills

- **mockfly-projects** — day-to-day project/endpoint/response workflows using these tools
- **mockfly-cli** — offline local mock serving, no cloud dependency
