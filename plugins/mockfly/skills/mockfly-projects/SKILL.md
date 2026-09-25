---
name: mockfly-projects
description: >-
  Create, import, and edit Mockfly mock-API projects, endpoints, responses,
  and conditional rules by calling Mockfly's public REST API. Use when asked
  to spin up a mock API, turn an OpenAPI/Postman/HAR file into mock
  endpoints, add or change a mock response, or make a mock respond
  differently based on the request. Also use when asked to turn
  demo-data-generator's output into a live mock backend on Mockfly instead
  of (or alongside) its Render deployment. Trigger terms: mock API, mock
  endpoint, Mockfly project, import OpenAPI, import Postman collection,
  conditional response, mock rules, demo-data-generator, demo mock API.
license: MIT
compatibility: Mockfly public REST API (see mockfly-api skill)
metadata:
  author: Omilia — community integration, not officially maintained by Mockfly
  version: "0.4.0"
  category: development
---

# Mockfly Projects, Endpoints, and Responses

Day-to-day workflows for managing Mockfly mocks via `curl` calls to the
public API. If auth isn't set up yet, use **mockfly-api** first — it also
has the full endpoint reference these workflows call.

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

Enforced identically through the API and the dashboard:

- 1 project as admin
- 4 endpoints per project
- 2 responses per endpoint

A `POST` beyond these limits returns 429. Don't retry — either delete
something to make room or note the limit back to the user; there's no
API-side override.

## Common Workflows

### Start a mock project from scratch

1. `POST /public/projects` (account key) — name it, get back a project id and its project API key
2. `POST /public/endpoints` (project key) — define method + path
3. `POST /public/endpoints/:endpointId/responses` — attach at least one response (status + body)
4. Optionally `PUT /public/endpoints/:endpointId/responses/:responseId/rules` if you need more than one response

Check `https://mockfly.dev/openapi.json` for each request body before
sending it — don't guess field names.

### Turn an existing spec into a mock

`POST /public/projects/import` (account key) with an OpenAPI, Postman
collection, or HAR file — it creates the project and its endpoints/
responses in one call, rather than building them up individually. Fetch
the OpenAPI spec first to confirm exactly how the import body should be
shaped (e.g. inline content vs. a URL). Confirm with the user which source
file to import before running this — it consumes one of their project
slots.

### Add an error-path or edge-case response

1. `GET /public/endpoints/:endpointId` to see existing responses and rules on that endpoint
2. `POST /public/endpoints/:endpointId/responses` for the new case (e.g. a 500, a timeout via `delay`, a
   malformed payload)
3. `PUT .../rules` so the right request pattern routes to it — e.g. a query
   param `?simulate=error`, or a specific header/body value

Don't silently overwrite an existing default response when the ask is to
*add* a case — duplicate it first (`POST .../responses/:responseId/duplicate`) if you want to branch from it.

### Update vs. delete

`PATCH` on a project/endpoint/response changes in place and keeps the same
id — prefer this over delete+recreate, since delete also drops history and
any rules attached to what you removed.

## Using with demo-data-generator

`demo-data-generator` produces one consolidated OpenAPI spec per demo at
`output/{group_name}/server/openapi/{group_name}_api.yaml`, meant to be
deployed as a custom FastAPI server on Render. That spec can also be
imported straight into a Mockfly project with `POST /public/projects/import`
— useful when a demo doesn't need the full Docker/Render pipeline, or when
you want a second, instantly-editable mock target.

**This is a real shortcut, not a full substitute — know the gap before
promising it "just works":**

- **Endpoint shapes import automatically.** Paths, methods, request/response
  schemas from the spec become real endpoints in the new project — this
  part genuinely is automatic.
- **Seed data does not carry over automatically.** demo-data-generator's
  `seed_data.json` (the specific account numbers, balances, names referenced
  consistently across transcripts and documents) isn't part of the OpenAPI
  spec — it's read at runtime by the generated FastAPI app. An OpenAPI
  import only gives you schema-shaped default responses. To keep the demo's
  data consistent, manually set each imported endpoint's response body to
  match the matching records in `seed_data.json` — there's no automatic
  sync between the two files.
- **Magic test values need manual rules.** `ERROR-TEST`, `TIMEOUT-TEST`,
  `DECLINED-TEST` are custom branches in the generated `app.py`, not
  something the OpenAPI spec declares. Reproduce them in Mockfly with
  `PUT .../rules` (e.g. a rule matching `account_number == "ERROR-TEST"` →
  a 500 response) if the demo needs them.
- **Auth header mismatch is harmless.** The spec declares `X-API-Key`
  security, matching the FastAPI server's own check. A Mockfly-hosted
  endpoint doesn't enforce that header by default and will just respond
  regardless — fine for a demo, but don't assume the imported mock
  reproduces the 401-on-bad-key behavior unless you add a rule for it too.

Tell the user which of these gaps matter for their specific demo before
treating the import as done — a demo where the agent looks up a customer
by name and gets back generic Faker data instead of the name it was just
told about will look broken, not just incomplete.

## Reading Back State

Before creating or editing, prefer `GET /public/endpoints` /
`GET /public/endpoints/:endpointId` over assuming what's already there —
Mockfly projects are often edited by hand in the web app between Claude
Code sessions, so cached assumptions about existing endpoints can be stale.

## Related Skills

- **mockfly-api** — auth, full endpoint reference, curl examples, troubleshooting
- **mockfly-cli** — serve a pulled snapshot of a project locally, offline
