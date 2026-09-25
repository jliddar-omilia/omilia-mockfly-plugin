# omilia-mockfly-plugin

A Claude Code plugin marketplace that connects Claude Code to
[Mockfly](https://mockfly.dev/) (hosted mock-API generator) via Mockfly's
official MCP server, plus three skills covering setup, day-to-day project
work, and offline local serving.

Built for Omilia engineers who want Mockfly usable from Claude Code the same
way the built-in Render skill pack makes Render usable — one plugin install,
then natural-language requests instead of hand-editing the dashboard.

## What's in it

| Component | What it does |
|---|---|
| `mockfly` MCP server | Bundles Mockfly's official `mockfly-mcp-client` (npm), pre-wired with `userConfig` so Claude Code prompts you for your API keys on install instead of hand-editing JSON |
| `mockfly-mcp` skill | Setup, auth (account key vs project key), tool catalog, troubleshooting |
| `mockfly-projects` skill | Create/import projects, manage endpoints/responses/conditional rules, free-plan limits |
| `mockfly-cli` skill | Offline local mock serving via the separate open-source `mockfly-cli` tool |

## Install

```
/plugin marketplace add liddar12/omilia-mockfly-plugin
/plugin install mockfly@omilia-mockfly-plugin
```

Then run `/config`, find the **Mockfly** section, and fill in:

- **Mockfly account API key** — `app.mockfly.dev/api-keys`
- **Mockfly project API key** — from a project's settings page

Both are stored in Claude Code's secure credential store, not plaintext.
Each engineer uses their own keys — nothing is shared in this repo.

Restart Claude Code (or start a new session), then confirm with
`claude mcp list` or `/mcp`. If MCP tools don't show up, see the
`mockfly-mcp` skill's troubleshooting reference.

## Status

- Built against Mockfly's public docs (`mockfly.dev/docs/`) and the
  `mockfly-mcp-client` npm package as of 2026-09-25.
- Mockfly's own docs list Claude Desktop and Antigravity as supported
  clients, not Claude Code by name. The server uses the standard MCP stdio
  config, so it should register the same way in Claude Code — this hasn't
  been confirmed on a real call yet. Please report back once you've tried
  it, and update this note.
- `mockfly-mcp-client` is closed source (npm-only, no public repo) — this
  plugin can configure it but not extend or fork it. `mockfly-cli` (used by
  the `mockfly-cli` skill) is open source.

## Development

This is a plain marketplace + plugin directory, no build step:

```
.claude-plugin/marketplace.json     # marketplace listing
plugins/mockfly/.claude-plugin/plugin.json   # plugin manifest, userConfig
plugins/mockfly/.mcp.json                    # MCP server config (see gotcha below)
plugins/mockfly/skills/              # the three skills
```

To iterate locally without publishing:

```
claude plugin validate ./plugins/mockfly
claude plugin validate .
```

To test a local edit against a running session, load it directly with
`--plugin-dir ./plugins/mockfly` instead of installing from the marketplace.

### Gotchas found while building this

- **MCP servers must go in `.mcp.json` at the plugin root, not inline in
  `plugin.json`.** An inline `mcpServers` key in `plugin.json` validates
  clean but the server silently never loads (confirmed on this Claude Code
  build with an isolated throwaway test plugin, not just this one). Filed
  as feedback; don't revert this to inline until that's fixed upstream.
- **Bump `version` in `plugin.json` after every edit, even for a local
  `directory`-sourced marketplace.** Installs are cached per-version at
  `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`, and that
  cache is *not* refreshed on `marketplace update` / reinstall unless the
  version string actually changes — contrary to what the docs say about
  local-directory sources picking up edits automatically. Also filed as
  feedback.
- After bumping the version, `claude plugin uninstall` +
  `claude plugin install ... --config KEY=VALUE` is the fastest way to force
  a clean re-cache and re-set sensitive config in one shot.
