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
| `mockfly-projects` skill | Create/import projects, manage endpoints/responses/conditional rules, plan limits, importing `demo-data-generator` output |
| `mockfly-cli` skill | Offline local mock serving via the separate open-source `mockfly-cli` npm tool |

No bundled MCP server, no plugin `userConfig` prompts — auth is plain
environment variables, because sensitive plugin config doesn't substitute
into skill content or Bash commands anyway (only into MCP/LSP server env).

## Capabilities

Ask Claude, in plain language, once this is installed and your keys are set:

- Create a mock API project from scratch, or import one from an existing
  OpenAPI spec, Postman collection, or HAR capture
- Add, edit, or delete mock endpoints and responses — including error
  cases, delays, and malformed-payload edge cases
- Set conditional rules so a mock replies differently depending on the
  request (query param, header, body content)
- List and inspect existing projects/endpoints before changing them
- Run a pulled snapshot of your mocks fully offline via `mockfly-cli`,
  with no cloud dependency
- Import a `demo-data-generator`-produced OpenAPI spec into a new Mockfly
  project as a faster alternative (or second target) to its Docker/Render
  deployment — see [Works with demo-data-generator](#works-with-demo-data-generator)
  below for what does and doesn't come along automatically

## Works with demo-data-generator

The `anthropic-skills:demo-data-generator` skill builds full Omilia Copilot
demo environments, including one consolidated OpenAPI spec per demo at
`output/{group_name}/server/openapi/{group_name}_api.yaml`, normally
deployed as a custom FastAPI app on Render.

That spec can be imported directly into Mockfly (`mockfly-projects` skill
covers this) as a faster, no-Docker alternative or a second live mock
target. **This is a partial, not total, automation** — be clear about the
difference before relying on it for a live demo:

| Carries over automatically | Needs manual work after import |
|---|---|
| Endpoint paths, methods, request/response shapes | The specific seed data (`seed_data.json` records) that transcripts and documents reference by name/account number |
| — | Magic test values (`ERROR-TEST`, `TIMEOUT-TEST`, `DECLINED-TEST`) — these are custom server logic, not part of the spec |
| — | `X-API-Key` enforcement — Mockfly won't reject requests missing it unless you add a rule for that too |

The two skills are independent and don't call each other automatically —
this only happens when you (or Claude, prompted by you) explicitly hand the
generated OpenAPI file to `mockfly-projects`' import workflow in the same
session.

## Install

```
/plugin marketplace add jliddar-omilia/omilia-mockfly-plugin
/plugin install mockfly@omilia-mockfly-plugin
```

Then set your own Mockfly keys — each engineer uses their own, nothing is
shared in this repo. The two keys are deliberately set up differently:

```bash
# Account key: long-lived, set once. Add to ~/.zshrc / ~/.bash_profile
# (or `setx MOCKFLY_ACCOUNT_API_KEY "..."` on Windows), then open a new terminal.
export MOCKFLY_ACCOUNT_API_KEY="mf_..."   # app.mockfly.dev/api-keys

# Project key: short-lived by design — projects here are typically torn
# down after use. Export it fresh, per terminal session, right before
# starting Claude Code. Do NOT add this one to a shell profile.
export MOCKFLY_API_KEY="..."              # a project's settings page
claude
```

Full step-by-step instructions, including Windows (native PowerShell and
WSL), are in [`INSTALL.md`](INSTALL.md).

Verify with `echo $MOCKFLY_API_KEY` in the terminal you're running Claude
Code from. See the `mockfly-api` skill's troubleshooting reference for
401/403/429 causes.

**Never paste either key into a chat with Claude** — only ever into the
terminal directly. A key pasted into chat becomes part of the stored
conversation log the same way a file would.

## Status

- Built against Mockfly's public docs (`mockfly.dev/docs/`) and its
  OpenAPI spec (`mockfly.dev/openapi.json`) as of 2026-09-25.
- The MCP-based version (bundling `mockfly-mcp-client`) was built, tested,
  and abandoned in favor of this REST approach after confirming the org
  policy block — see git history (`plugins/mockfly/.claude-plugin/
  plugin.json` pre-0.2.0) if you want that version as a reference.
- The free-plan limits documented in the skills (1 project, 4
  endpoints/project, 2 responses/endpoint) don't apply on a paid plan —
  ignore that section if you're on one.

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
- **Sensitive plugin `userConfig` values never reach Bash commands or
  skill content** — only MCP/LSP server `env`. This is why keys here are
  plain shell env vars instead of plugin config, and why an MCP-free
  design can't use `/config` for secrets at all.
