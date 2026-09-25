# omilia-mockfly-plugin

A Claude Code plugin marketplace that makes [Mockfly](https://mockfly.dev/)
(hosted mock-API generator) usable from Claude Code: three skills that call
Mockfly's public REST API directly via `curl`, covering auth/setup,
day-to-day project work, and offline local serving.

Built for Omilia engineers who want Mockfly usable from Claude Code the same
way the built-in Render skill pack makes Render usable — install once, then
natural-language requests instead of hand-editing the dashboard.

## Why REST, not MCP

Mockfly publishes an official MCP server (`mockfly-mcp-client`, on npm).
This plugin doesn't use it: many Claude Code installations — including the
one this was built against — are locked by admin policy to a specific
allowlist of MCP servers (`allowManagedMcpServersOnly: true`), and
`mockfly-mcp-client` isn't on it. That same policy would likely block
almost any third-party MCP server not pre-approved by an org, so calling
Mockfly's REST API directly through the Bash tool — which isn't subject to
that allowlist — is the version that actually works, not just in the demo.
If your Claude Code isn't locked down that way, Mockfly's own MCP server is
also a valid option; this plugin just doesn't depend on it.

## What's in it

| Component | What it does |
|---|---|
| `mockfly-api` skill | Auth setup (env vars, no MCP), full REST endpoint reference, curl examples, troubleshooting |
| `mockfly-projects` skill | Create/import projects, manage endpoints/responses/conditional rules, free-plan limits |
| `mockfly-cli` skill | Offline local mock serving via the separate open-source `mockfly-cli` npm tool |

No bundled MCP server, no plugin `userConfig` prompts — auth is two plain
environment variables, because sensitive plugin config doesn't substitute
into skill content or Bash commands anyway (only into MCP/LSP server env).

## Install

```
/plugin marketplace add liddar12/omilia-mockfly-plugin
/plugin install mockfly@omilia-mockfly-plugin
```

Then set your own Mockfly keys as environment variables — each engineer
uses their own, nothing is shared in this repo:

```bash
# add to ~/.zshrc or ~/.bashrc, then restart your shell / Claude Code session
export MOCKFLY_ACCOUNT_API_KEY="mf_..."   # app.mockfly.dev/api-keys
export MOCKFLY_API_KEY="..."              # a project's settings page
```

Verify with `echo $MOCKFLY_API_KEY` in a fresh terminal before asking Claude
to use it. See the `mockfly-api` skill for per-project scoping instead of a
global export, and its troubleshooting reference for 401/403/429 causes.

## Status

- Built against Mockfly's public docs (`mockfly.dev/docs/`) and its
  OpenAPI spec (`mockfly.dev/openapi.json`) as of 2026-09-25.
- The MCP-based version (bundling `mockfly-mcp-client`) was built, tested,
  and abandoned in favor of this REST approach after confirming the org
  policy block — see git history (`plugins/mockfly/.claude-plugin/
  plugin.json` pre-0.2.0) if you want that version as a reference.

## Development

Plain marketplace + plugin directory, no build step:

```
.claude-plugin/marketplace.json              # marketplace listing
plugins/mockfly/.claude-plugin/plugin.json   # plugin manifest
plugins/mockfly/skills/                      # the three skills
```

To iterate locally without publishing:

```
claude plugin validate ./plugins/mockfly
claude plugin validate .
```

To test a local edit against a running session, load it directly with
`--plugin-dir ./plugins/mockfly` instead of installing from the marketplace.

### Gotchas found while building this

- **A Claude Code MCP server that's blocked by an admin allowlist doesn't
  show up as "failed" anywhere** — not in `/mcp`, not in `claude mcp list`,
  not in `claude --debug` startup output. It's silently absent, which looks
  identical to a config mistake. If a plugin-bundled MCP server never
  appears at all (not even as an error), check
  `~/.claude/remote-settings.json` for `allowManagedMcpServersOnly` and
  `allowedMcpServers` before assuming the plugin is broken.
- **MCP servers must go in `.mcp.json` at the plugin root, not inline in
  `plugin.json`.** An inline `mcpServers` key validates clean but the
  server never loads on this Claude Code build (confirmed with an isolated
  throwaway test plugin too, not just this one). Filed as feedback.
- **Bump `version` in `plugin.json` after every edit**, even for a local
  `directory`-sourced marketplace. Installs cache per-version at
  `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`, and that
  cache isn't refreshed on reinstall unless the version string changes —
  contrary to what the docs say about local-directory sources picking up
  edits automatically. Also filed as feedback.
