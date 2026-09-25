---
name: mockfly-api
description: >-
  Call Mockfly's public REST API directly (via curl in Bash) to manage mock
  API projects, endpoints, and responses. Use when asked to set up Mockfly
  auth, when a call returns 401/403/429, or before any Mockfly operation to
  confirm the request shape against the live OpenAPI spec. Trigger terms:
  Mockfly API, api.mockfly.dev, MOCKFLY_API_KEY, MOCKFLY_ACCOUNT_API_KEY,
  mock API auth.
license: MIT
compatibility: Mockfly public REST API (api.mockfly.dev)
metadata:
  author: Omilia — community integration, not officially maintained by Mockfly
  version: "0.4.0"
  category: operations
---

# Mockfly Public API

Mockfly's official MCP server (`mockfly-mcp-client`) exists, but many
organizations lock Claude Code to an admin-managed MCP server allowlist that
won't include it. This skill instead calls Mockfly's **public REST API**
directly with `curl` through the Bash tool — no MCP server, no allowlist
dependency, works everywhere Bash and network access do.

The **mockfly-projects** skill covers day-to-day workflows built on these
calls. The **mockfly-cli** skill covers the separate offline CLI.

## Before You Call Anything

Mockfly's OpenAPI spec is the source of truth for exact request/response
bodies: **`https://mockfly.dev/openapi.json`**. Fetch it (or the relevant
part of it) before constructing a `create`/`import`/`update` call whose body
shape you're not already certain of — don't guess field names. The
endpoint list, auth, and limits below are stable enough to hardcode; request
bodies are not.

## Connection Details

| Property | Value |
|---|---|
| Base URL | `https://api.mockfly.dev` |
| Auth header | `Authorization: <api_key>` — the **raw key value**, no `Bearer ` prefix |
| Spec | `https://mockfly.dev/openapi.json` |
| Docs | `https://mockfly.dev/docs/public-api/` |

## Authentication

Two independent keys, with deliberately different lifetimes — this is the
default setup, not a fallback:

| Key | Env var | Lifetime | Setup |
|---|---|---|---|
| Account API key | `MOCKFLY_ACCOUNT_API_KEY` | Long-lived — set once | Shell profile, persists forever |
| Project API key | `MOCKFLY_API_KEY` | Short-lived — projects get created and torn down often | Per-session export, never saved to a profile |

Neither goes through Claude Code plugin config (`userConfig`) — sensitive
plugin config values don't substitute into skill content or Bash commands,
only into MCP/LSP server env. A shell env var is what actually reaches a
`curl` call here.

### Account key — one-time setup

Add to `~/.zshrc` / `~/.bash_profile` (macOS/Linux) or set with `setx`
(Windows) once, and never touch it again unless it's rotated:

```bash
export MOCKFLY_ACCOUNT_API_KEY="mf_..."   # then open a new terminal
```

### Project key — quick per-session setup (the default)

Projects here are typically temporary and torn down after use, so don't
add this one to a profile file — that just accumulates stale keys.
Instead, export it fresh in the terminal, for that session only, right
before starting Claude Code:

```bash
export MOCKFLY_API_KEY="paste_here"   # in your terminal — not in this chat
claude
```

Windows PowerShell equivalent (also session-only, not `setx`):

```powershell
$env:MOCKFLY_API_KEY = "paste_here"
claude
```

Got a new project and need a new key mid-session? Tell the user to run
the export in a **new terminal window**, restart the Claude Code session
in it, and confirm — the running session's Bash tool won't pick up a
change made in a different, already-running shell.

### Rule for Claude, not just the user

**Never ask the user to paste the raw key value into chat**, for either
key — not even for a "temporary, low-risk" project key. A key pasted into
a message becomes part of the stored conversation log, which is exactly
what pasting it anywhere else would also do. If either env var comes back
empty when checked (`echo $MOCKFLY_API_KEY`), give the user the exact
export command to run themselves in their own terminal and ask them to
confirm once done — the same pattern as the account key's one-time setup,
just without adding it to a profile file.

Verify either key is visible to Claude Code's Bash tool with
`echo $MOCKFLY_API_KEY` — should print the key, not an empty line.

## Endpoint Reference

Verified directly against the raw spec (`curl -s
https://mockfly.dev/openapi.json`, not a summarized read of it) — 10
paths total, all listed here.

### Projects (account key)

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/public/projects` | List accessible projects |
| `POST` | `/public/projects` | Create an empty project |
| `POST` | `/public/projects/import` | Create a project with endpoints/responses in one call. **Takes Mockfly's own `{project, endpoints, folders, environment}` shape, not a raw OpenAPI/Postman/HAR file** — the dashboard converts those on upload; the API doesn't. Convert the source spec yourself first — see `mockfly-projects` |
| `PATCH` | `/public/projects/:projectId` | Update project name/tags (admin only) — only these two fields are settable, not `useProxy`/`proxyUrl`/`allowedUsers` |
| `DELETE` | `/public/projects/:projectId` | Delete a project (admin only) |

### Endpoints and responses (project key)

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/public/endpoints` | List a project's endpoints |
| `POST` | `/public/endpoints` | Create an endpoint |
| `GET` | `/public/endpoints/:endpointId` | Get one endpoint, responses expanded, including each response's `bodyHistory` |
| `PATCH` | `/public/endpoints/:endpointId` | Update an endpoint — also how you set `defaultResponse` or per-endpoint `proxyConfiguration` |
| `DELETE` | `/public/endpoints/:endpointId` | Delete an endpoint |
| `POST` | `/public/endpoints/:endpointId/responses` | Create a mock response — `rules` can be included in this same call, no separate rules call needed |
| `PATCH` | `/public/endpoints/:endpointId/responses/:responseId` | Update a response |
| `DELETE` | `/public/endpoints/:endpointId/responses/:responseId` | Delete a response |
| `POST` | `/public/endpoints/:endpointId/responses/:responseId/duplicate` | Duplicate a response |
| `PUT` | `/public/endpoints/:endpointId/responses/:responseId/rules` | Replace a response's whole rule set (full replace, not merge) |

### API Hub (no auth)

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/hub/catalog` | List Mockfly's free public sample APIs — no account or key needed. Good for a quick "just give me something that works" mock, not for a specific shape |

### Example calls

List projects (no body needed, safe to run to sanity-check auth):

```bash
curl -s https://api.mockfly.dev/public/projects \
  -H "Authorization: $MOCKFLY_ACCOUNT_API_KEY"
```

List a project's endpoints:

```bash
curl -s https://api.mockfly.dev/public/endpoints \
  -H "Authorization: $MOCKFLY_API_KEY"
```

For any call with a body (`POST`/`PATCH`/`PUT`), fetch the relevant schema
from `https://mockfly.dev/openapi.json` first, then build the `curl -X
POST ... -H "Content-Type: application/json" -d '{...}'` call from that.

## Rate Limits

Free plan, enforced identically through the API and the dashboard:

- 1 project as admin
- 4 endpoints per project
- 2 responses per endpoint

## HTTP Status Codes

| Code | Meaning |
|---|---|
| 200 | Success |
| 400 | Invalid payload, or a referenced resource doesn't exist |
| 401 | Missing/invalid API key |
| 403 | Wrong key type for this operation (account vs. project) |
| 429 | Free-plan limit exceeded |
| 500 | Server error |

## Common Mistakes

| Mistake | Fix |
|---|---|
| `Authorization: Bearer <key>` | Wrong — no `Bearer` prefix, just the raw key |
| 401 on every call | Env var unset or empty in this shell — `echo $MOCKFLY_API_KEY` to check |
| 403 on a project-level call | You used the account key where the project key was needed, or vice versa |
| 429 on create/import | Free-plan limit — see above, no API-side override |
| Guessing an import/create body shape | Fetch `https://mockfly.dev/openapi.json` first instead |

## Troubleshooting

See `references/troubleshooting.md` for more detail on auth and request
failures.

## Related Skills

- **mockfly-projects** — day-to-day project/endpoint/response workflows using these calls
- **mockfly-cli** — offline local mock serving, no cloud dependency
