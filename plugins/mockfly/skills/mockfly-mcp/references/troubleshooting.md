# Mockfly MCP Troubleshooting

## Connection

**`claude mcp list` doesn't show `mockfly`**
- If installed via the plugin: confirm the plugin is enabled (`/plugin`) and
  that you restarted Claude Code (or started a new session) after enabling.
- If installed manually: re-run the `claude mcp add` command from
  `mockfly-mcp` and check for typos in `--env` flags.

**Server shows as failed / crashes on startup**
- `npx -y mockfly-mcp-client` requires network access on first run to fetch
  the package. If offline, it will fail — this is expected; the MCP server
  needs Mockfly's cloud API regardless of network for the npx fetch itself.
- Check `node`/`npx` are on `PATH` for the shell Claude Code spawns from.

## Authentication

**401 Unauthorized on every call**
- One or both keys are empty, expired, or were copied with surrounding
  whitespace. Re-copy from the dashboard and re-run `/config`.

**403 Forbidden on project/endpoint/response calls**
- You likely set only the account key, or swapped the two keys. Project-level
  tools (`get_endpoints`, `create_endpoint`, etc.) need `MOCKFLY_API_KEY`
  specifically — the per-project key, not the account key.

**429 on create/import**
- Free plan limits apply through the API exactly as in the dashboard: 1
  project as admin, 4 endpoints per project, 2 responses per endpoint.
  Upgrading the plan removes these limits; there's no MCP-side workaround.

## Version drift

`mockfly-mcp-client` is closed source and npm-only — there's no changelog
beyond the npm version history. If a tool call's shape changes unexpectedly
after `npx` picks up a new version, check
`https://mockfly.dev/docs/mockfly-mcp-client/` for updated tool
descriptions before assuming a bug in this skill's documentation.
