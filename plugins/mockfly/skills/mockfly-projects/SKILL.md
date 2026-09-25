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
  version: "0.5.0"
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
deployed as a custom FastAPI server on Render. That spec — plus the seed
data and magic test values that server implements — can be reproduced on
Mockfly with a scripted sequence of API calls, not just the one import
call. Only one step at the end is actually manual.

**Requires a paid Mockfly plan.** Full replication needs many responses
per endpoint (one per seed record, plus the magic values, plus the auth
check) — the free plan's 2-responses-per-endpoint cap makes this
impractical. On free, stop after step 1 and accept the gaps from the
previous version of this section.

### The procedure

1. **Import the spec**: `POST /public/projects/import` (account key) with
   the OpenAPI YAML — creates the project and endpoint scaffolding. Note
   the project's mock base URL from the response
   (`https://api.mockfly.dev/mocks/{namespace}`) — you'll need it in step 5.

2. **Find and read the seed data.** Look for `seed_data.json` under
   `output/{group_name}/server/` first — that's the path the top-level
   generated-file tree in demo-data-generator's own SKILL.md documents.
   Its `references/mock-api-patterns.md` shows a slightly different
   internal path (`data/seed_data.json`) in an architecture example — if
   the first path doesn't exist, check the actual generated output tree
   for wherever it landed rather than assuming either path is right.

3. **Recreate each seed record as a response, per identifier-taking
   endpoint.** For each endpoint that looks something up by an identifier
   (account number, member ID, etc. — check the endpoint's OpenAPI
   parameters), and for each seed record in `seed_data.json`:
   - `POST /public/endpoints/:endpointId/responses` — body is that
     record's real fields, shaped to match the endpoint's response schema
   - `PUT .../responses/:responseId/rules` — rule: the identifier param
     `equal` that record's identifier value
   
   Confirm current rule semantics against
   `https://mockfly.dev/docs/conditional-response-mock-api/` before
   building these — as of this writing, responses on one endpoint use
   **last-match-wins** (when several rules match, the last one in the
   list is served), and the endpoint's one designated default response is
   the fallback when nothing matches. Add these seed-record responses
   right after the default.

4. **Add the magic test values, after the seed responses** (so they win
   under last-match-wins if a request somehow collides — it shouldn't,
   since `ERROR-TEST` etc. aren't real seed identifiers, but order still
   matters for correctness):
   - `ERROR-TEST` → rule: identifier `equal` `"ERROR-TEST"` → response
     status 500
   - `TIMEOUT-TEST` → same pattern → response with Mockfly's response
     `delay` field set to match the ~30s the real server sleeps for
   - `DECLINED-TEST` → only on payment/write endpoints → rule on the
     relevant field `equal` `"DECLINED-TEST"` → a declined-payment
     response body

5. **Add X-API-Key enforcement last**, so it overrides everything else
   when it fires: a rule group (Mockfly supports AND/OR grouping) —
   header `X-API-Key` `notExists` OR `notEqual`
   `"demo-api-key-{group_name}"` → 401 response. This is the highest
   -priority rule on the endpoint precisely because it's added last.

6. **The one manual step**: point the demo's Stage 2 API-spec upload (or
   whatever config in Omilia Copilot names the live API base URL) at the
   Mockfly project's mock base URL from step 1, instead of the Render
   deployment's URL. Nothing in this plugin has API access to Omilia
   Copilot itself, so this one step happens in the Copilot UI, same as
   the drag-and-drop upload demo-data-generator's own instructions
   already describe — it just points somewhere different.

### What this gets you vs. the earlier, simpler version

| | Import only | Full procedure above |
|---|---|---|
| Endpoint shapes | ✓ | ✓ |
| Seed data matches transcripts/documents | ✗ (generic schema defaults) | ✓ |
| Magic test values work | ✗ | ✓ |
| X-API-Key enforced | ✗ | ✓ |
| Plan required | Free is fine | Paid |
| Manual work | None | One config pointer in Copilot |

Tell the user up front whether they want the fast import-only version or
the full procedure — the full one is a lot more Mockfly API calls and
takes longer, but is the one that actually behaves like the Render
deployment it's replacing.

## Reading Back State

Before creating or editing, prefer `GET /public/endpoints` /
`GET /public/endpoints/:endpointId` over assuming what's already there —
Mockfly projects are often edited by hand in the web app between Claude
Code sessions, so cached assumptions about existing endpoints can be stale.

## Related Skills

- **mockfly-api** — auth, full endpoint reference, curl examples, troubleshooting
- **mockfly-cli** — serve a pulled snapshot of a project locally, offline
