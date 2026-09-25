# Mockfly API Troubleshooting

## Environment

**`curl` calls get 401 even though you set the env vars**
- Check the var is visible to the *current* shell: `echo $MOCKFLY_API_KEY`.
  If empty, either it was set in a different shell/tab, or it's only in a
  project `.env` that was never `source`d before starting Claude Code.
- Whitespace or quotes copied in from the dashboard can end up embedded in
  the value. Re-export cleanly: `export MOCKFLY_API_KEY="$(cat key.txt |
  tr -d '[:space:]')"` if in doubt, or just retype it.

**Works in one project, not another**
- You're using per-project `.env` scoping and this project doesn't have
  one, or has a stale key. Env vars don't inherit across unrelated shells —
  only from the shell that actually launched this Claude Code session.

## Authentication

**401 Unauthorized on every call**
- Key is empty, expired, or was revoked (e.g. after being rotated for
  security reasons). Get a fresh one from the dashboard and re-export.

**403 Forbidden on `/public/endpoints*` calls**
- You're sending the account key where the project key belongs, or vice
  versa. Account key → `/public/projects*` only. Project key →
  `/public/endpoints*` only.

**429 on create/import**
- Free plan limits apply exactly as in the dashboard: 1 project as admin,
  4 endpoints per project, 2 responses per endpoint. Upgrading the plan
  removes these; there's no API-side override.

## Request Shape

**400 on a `POST`/`PATCH`/`PUT` call**
- Don't guess the body. Fetch `https://mockfly.dev/openapi.json`
  (or the relevant path within it) and match the schema exactly —
  field names and required/optional status can differ from what
  seems intuitive.

## Why Not the Official MCP Server?

Mockfly publishes `mockfly-mcp-client` on npm as an official MCP server.
It's a fine option if your Claude Code installation isn't locked to an
admin-managed MCP server allowlist. If it is (check `/mcp` — a server
that's blocked by policy doesn't show up at all, not even as "failed"),
this REST-via-curl approach is the one that actually works, since Bash/curl
calls aren't subject to that allowlist.
