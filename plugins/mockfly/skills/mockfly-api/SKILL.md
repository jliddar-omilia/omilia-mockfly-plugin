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
  version: "0.2.0"
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

Two independent keys. Set both as plain environment variables — **not**
Claude Code plugin config, since sensitive plugin `userConfig` values don't
substitute into skill content or Bash commands, only into MCP/LSP server
env. A shell env var is what actually reaches a `curl` call here.

| Key | Suggested env var | Scope | Used for |
|---|---|---|---|
| Account API key | `MOCKFLY_ACCOUNT_API_KEY` | Account | `/public/projects*` |
| Project API key | `MOCKFLY_API_KEY` | One project | `/public/endpoints*` |

### Set them up

Global (works in every project, every session):

```bash
# add to ~/.zshrc or ~/.bashrc, then restart your shell / Claude Code session
export MOCKFLY_ACCOUNT_API_KEY="mf_..."
export MOCKFLY_API_KEY="..."
```

Per-project instead (if different projects use different Mockfly accounts):

```bash
# in the project's .env (gitignored!), then `source .env` before starting Claude Code
MOCKFLY_ACCOUNT_API_KEY=mf_...
MOCKFLY_API_KEY=...
```

Verify Claude Code's Bash tool can see them: `echo $MOCKFLY_API_KEY` should
print the key, not an empty line, in a fresh session.

**Never** paste a raw key value into chat, into a file this skill writes,
or into a command whose output gets logged/shared. Reference the env var by
name in commands (`$MOCKFLY_API_KEY`), never the literal value.

## Endpoint Reference

### Projects (account key)

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/public/projects` | List accessible projects |
| `POST` | `/public/projects` | Create an empty project |
| `POST` | `/public/projects/import` | Create a project pre-populated from OpenAPI/Postman/HAR — check the spec for the exact body |
| `PATCH` | `/public/projects/:projectId` | Update project name/tags (admin only) |
| `DELETE` | `/public/projects/:projectId` | Delete a project (admin only) |

### Endpoints and responses (project key)

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/public/endpoints` | List a project's endpoints |
| `POST` | `/public/endpoints` | Create an endpoint |
| `GET` | `/public/endpoints/:endpointId` | Get one endpoint, responses expanded |
| `PATCH` | `/public/endpoints/:endpointId` | Update an endpoint |
| `DELETE` | `/public/endpoints/:endpointId` | Delete an endpoint |
| `POST` | `/public/endpoints/:endpointId/responses` | Create a mock response |
| `PATCH` | `/public/endpoints/:endpointId/responses/:responseId` | Update a response |
| `DELETE` | `/public/endpoints/:endpointId/responses/:responseId` | Delete a response |
| `POST` | `/public/endpoints/:endpointId/responses/:responseId/duplicate` | Duplicate a response |
| `PUT` | `/public/endpoints/:endpointId/responses/:responseId/rules` | Replace conditional rules |

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
