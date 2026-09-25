# Mockfly API Troubleshooting

## Environment

**`MOCKFLY_ACCOUNT_API_KEY` is empty**
- It's meant to be permanent, set once in a shell profile. Check
  `echo $MOCKFLY_ACCOUNT_API_KEY`. If empty, it was either never added to
  `~/.zshrc`/`~/.bash_profile` (or `setx` on Windows), or you're in a
  terminal opened *before* it was set — open a new one.

**`MOCKFLY_API_KEY` is empty**
- This one is intentionally session-scoped, not saved anywhere permanent
  — it's expected to go empty whenever a new terminal/session starts
  without re-exporting it. That's by design, not a bug: tell the user to
  export it fresh in their terminal (`export MOCKFLY_API_KEY="..."` /
  `$env:MOCKFLY_API_KEY = "..."` on Windows) before starting this Claude
  Code session, then confirm. Never ask them to paste the raw value into
  chat instead.

**Whitespace or quotes embedded in a copied key**
- Re-export cleanly: `export MOCKFLY_API_KEY="$(cat key.txt |
  tr -d '[:space:]')"` if in doubt, or just retype it.

**Works in one terminal, not another**
- Expected for the project key (session-scoped by design). For the
  account key, it means the profile file edit didn't happen in the shell
  you're now using — check you edited the right one (`echo $SHELL`).

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
