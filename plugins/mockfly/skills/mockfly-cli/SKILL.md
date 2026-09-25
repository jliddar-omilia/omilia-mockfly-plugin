---
name: mockfly-cli
description: >-
  Serve Mockfly mock APIs locally and fully offline using the mockfly-cli
  npm tool, as an alternative to the cloud-hosted mocks when there's no
  network, when running in CI, or when the Mockfly MCP server isn't
  connected. Use when asked to run mocks locally, work offline, or add mocks
  to a CI pipeline. Trigger terms: mockfly-cli, offline mock, local mock
  server, mockfly pull, mockfly serve.
license: MIT
compatibility: mockfly-cli (npm, open source)
metadata:
  author: Omilia — community integration, not officially maintained by Mockfly
  version: "0.1.0"
  category: development
---

# Mockfly Offline CLI

`mockfly-cli` is a separate, open-source tool from the MCP server: it pulls
a **read-only snapshot** of your Mockfly projects and serves them locally
with the same response engine Mockfly runs in production — no cloud
round-trip needed once pulled. Source:
`https://github.com/zamarrowski/mockfly-cli`.

Use **mockfly-projects** (via MCP) to actually create or edit mocks. Use
this skill to run them locally afterward — for offline dev, flaky-network
environments, or CI.

## Install

```bash
npm install -g mockfly-cli
```

Or run ad hoc with `npx mockfly-cli <command>`.

## Commands

| Command | What it does |
|---|---|
| `mockfly login [--key <mf_...>]` | Save an account API key to `~/.mockfly/config.json` |
| `mockfly pull [projects...]` | Snapshot all — or named — projects to `~/.mockfly/projects` |
| `mockfly serve [--port 4000]` | Serve every pulled project locally, offline |
| `mockfly list` | Show what's pulled and how stale |
| `mockfly rm <project>` | Remove a pulled project |
| `mockfly whoami` | Show the active key and API URL |
| `mockfly logout` | Delete the saved key |

Typical loop:

```bash
mockfly login          # once, while online
mockfly pull            # snapshot current state
mockfly serve           # offline from here on
```

Each project mounts under its slug and a friendly alias, e.g.
`http://localhost:4000/user-api`.

## How It Works

`pull` writes each project (endpoints, responses, rules, env vars) to a
plain JSON file. `serve` loads those files and answers with a local copy of
Mockfly's response engine — rules, Faker templating, placeholders all work
offline. Nothing is written back: to change a mock, edit it in the web app
(or via MCP) and `pull` again.

- Proxy-configured endpoints are served as mocks locally — there's no real
  network to proxy to offline. A note prints when this happens.
- Requests log to stdout, not the cloud dashboard.

## Security Notes

- `mockfly login` stores the API key in plaintext at
  `~/.mockfly/config.json` (mode `600`) — same model as `~/.npmrc`. Use
  `mockfly logout` to remove it, and revoke from the dashboard if needed.
- Pulled snapshots include the project's **environment variables**. Don't
  `--dir` a pull into a repo path without gitignoring it — the file
  contains those secrets in plain text.
- The local server binds all interfaces — fine for local dev, not for
  exposing to a network.

## Configuration

| Env var | Purpose |
|---|---|
| `MOCKFLY_API_KEY` | Overrides the saved key |
| `MOCKFLY_API_URL` | Overrides the API base (self-hosted / staging) |

## Related Skills

- **mockfly-api** — call Mockfly's cloud API directly, auth and endpoint reference
- **mockfly-projects** — create/edit the projects this CLI then serves offline
