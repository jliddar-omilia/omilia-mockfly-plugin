---
name: mockfly-projects
description: >-
  Create, import, and edit Mockfly mock-API projects, endpoints, responses,
  and conditional rules using the Mockfly MCP tools. Use when asked to spin
  up a mock API, turn an OpenAPI/Postman/HAR file into mock endpoints, add or
  change a mock response, or make a mock respond differently based on the
  request. Trigger terms: mock API, mock endpoint, Mockfly project, import
  OpenAPI, import Postman collection, conditional response, mock rules.
license: MIT
compatibility: mockfly-mcp-client tool catalog (see mockfly-mcp skill)
metadata:
  author: Omilia — community integration, not officially maintained by Mockfly
  version: "0.1.0"
  category: development
---

# Mockfly Projects, Endpoints, and Responses

Day-to-day workflows for managing Mockfly mocks through the MCP tools. If
MCP tools aren't connected yet, use **mockfly-mcp** first.

## Concepts

| Term | Meaning |
|---|---|
| Project | A container of mock endpoints, served at its own subdomain/slug under `https://api.mockfly.dev/mocks/{namespace}` |
| Endpoint | One mocked route: a method + path (e.g. `GET /users/:id`) |
| Response | One possible reply for an endpoint — status, body, headers, delay |
| Rules | Conditions (on query, body, headers, etc.) that pick which response fires for a given request |

An endpoint can have multiple responses (success, error, edge case) selected
by rules, or a single default response with no rules.

## Free Plan Limits

Enforced identically through the MCP tools and the dashboard:

- 1 project as admin
- 4 endpoints per project
- 2 responses per endpoint

A `create_endpoint` or `create_response` call beyond these limits returns
429. Don't retry — either delete something to make room or note the limit
back to the user; there's no MCP-side override.

## Common Workflows

### Start a mock project from scratch

1. `create_project` — name it, get back a project id and its project API key
2. `create_endpoint` — define method + path
3. `create_response` — attach at least one response (status + body)
4. Optionally `modify_rules` if you need more than one response

### Turn an existing spec into a mock

Use `import_project` (account key) with an OpenAPI, Postman collection, or
HAR file — it creates the project and its endpoints/responses in one call,
rather than building them up individually. Confirm with the user which
source file to import before running this — it consumes one of their
project slots.

### Add an error-path or edge-case response

1. `get_endpoint_detail` to see existing responses and rules on that endpoint
2. `create_response` for the new case (e.g. a 500, a timeout via `delay`, a
   malformed payload)
3. `modify_rules` so the right request pattern routes to it — e.g. a query
   param `?simulate=error`, or a specific header/body value

Don't silently overwrite an existing default response when the ask is to
*add* a case — `duplicate_response` first if you want to branch from it.

### Update vs. delete

`update_project` / `edit_endpoint` / `edit_response` change in place and
keep the same id — prefer these over delete+recreate, since delete also
drops history and any rules attached to what you removed.

## Reading Back State

Before creating or editing, prefer `get_endpoints` / `get_endpoint_detail`
over assuming what's already there — Mockfly projects are often edited by
hand in the web app between Claude Code sessions, so cached assumptions
about existing endpoints can be stale.

## Related Skills

- **mockfly-mcp** — connect and authenticate the MCP server, full tool list
- **mockfly-cli** — serve a pulled snapshot of a project locally, offline
