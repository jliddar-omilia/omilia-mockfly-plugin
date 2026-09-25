---
name: mockfly-projects
description: >-
  Create, import, and edit Mockfly mock-API projects, endpoints, responses,
  and conditional rules by calling Mockfly's public REST API. Use when asked
  to spin up a mock API, turn an OpenAPI/Postman/HAR file into mock
  endpoints, add or change a mock response, or make a mock respond
  differently based on the request. Trigger terms: mock API, mock endpoint,
  Mockfly project, import OpenAPI, import Postman collection, conditional
  response, mock rules.
license: MIT
compatibility: Mockfly public REST API (see mockfly-api skill)
metadata:
  author: Omilia — community integration, not officially maintained by Mockfly
  version: "0.2.0"
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

## Reading Back State

Before creating or editing, prefer `GET /public/endpoints` /
`GET /public/endpoints/:endpointId` over assuming what's already there —
Mockfly projects are often edited by hand in the web app between Claude
Code sessions, so cached assumptions about existing endpoints can be stale.

## Related Skills

- **mockfly-api** — auth, full endpoint reference, curl examples, troubleshooting
- **mockfly-cli** — serve a pulled snapshot of a project locally, offline
