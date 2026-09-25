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
  version: "0.6.0"
  category: development
---

# Mockfly Projects, Endpoints, and Responses

Day-to-day workflows for managing Mockfly mocks via `curl` calls to the
public API. If auth isn't set up yet, use **mockfly-api** first — it also
has the full endpoint reference these workflows call.

This file is written against the actual OpenAPI schema at
`https://mockfly.dev/openapi.json` (fetched and parsed directly, not
summarized) — pull the current version before relying on an exact field
name here; Mockfly can add fields without notice.

## Concepts

| Term | Meaning |
|---|---|
| Project | A container of mock endpoints. Its mock server is served at `https://<slug>.mockfly.dev`, where `slug` comes back on the `Project` object from create/import — **not** `api.mockfly.dev/mocks/{namespace}`, despite what an earlier version of this file said |
| Endpoint | One mocked route: a method + path (e.g. `GET /users/:id`) |
| Response | One possible reply for an endpoint — status, body, `isEnabled`, `rules` |
| Rules | Conditions (`Rule` or a `RuleGroup` of them) that pick which response fires for a given request |

An endpoint can have multiple responses (success, error, edge case) picked
by rules, or a single unconditional one with no rules — that unconditional
one is what serves as the fallback ("default") when nothing else matches.
`PATCH /public/endpoints/:endpointId` with `defaultResponse: <responseId>`
sets this explicitly instead of relying on convention.

## Free Plan Limits

Enforced identically through the API and the dashboard:

- 1 project as admin
- 4 endpoints per project
- 2 responses per endpoint

A `POST` beyond these limits returns 429. Don't retry — either delete
something to make room or note the limit back to the user; there's no
API-side override. Doesn't apply on a paid plan.

## Common Workflows

### Start a mock project from scratch

1. `POST /public/projects` (account key) — name it, get back a project id, `slug` (its mock URL: `https://<slug>.mockfly.dev`), and `privateApiKey` (the project key — save it, it's only returned here and on update)
2. `POST /public/endpoints` (project key) — define method + path
3. `POST /public/endpoints/:endpointId/responses` — attach at least one response. **Include `rules` directly in this call** (`CreateResponseRequest` takes a `rules` array) rather than following up with a separate `PUT .../rules` call — same result, one fewer round trip.

Check `https://mockfly.dev/openapi.json` for each request body before
sending it — don't guess field names.

### Turn an existing OpenAPI/Postman/HAR spec into a mock

**The import endpoint does not accept a raw spec file.** `POST
/public/projects/import` takes Mockfly's own shape
(`ImportProjectRequest`: `{project: {name}, endpoints: [...], folders,
environment}`), described in the schema as "the dashboard's Export to
JSON payload." Mockfly's OpenAPI/Postman/HAR import is a dashboard-only
convenience — the web UI parses the file and converts it before saving;
the public API doesn't expose that conversion step.

So to import a spec via the API, do the conversion yourself first:

1. Parse the source spec (fetch/read it, don't guess its shape)
2. For each operation, build an `ImportEndpoint`: `{path, method,
   responses: [...]}` — map path parameters to Mockfly's `:param` syntax,
   and derive at least one `ImportEndpointResponse` (`{status, body,
   rules}`) per operation from its documented example/schema
3. `POST /public/projects/import` (account key) with the assembled
   `{project: {name}, endpoints: [...]}` body — creates everything in one
   call

This is the same mechanism the demo-data-generator procedure below uses,
just without the seed-data/magic-value/auth-rule layers.

### Add an error-path or edge-case response

1. `GET /public/endpoints/:endpointId` to see existing responses and rules on that endpoint
2. `POST /public/endpoints/:endpointId/responses` for the new case (status, body, and its `rules` in the same call)
3. If adding to an *existing* response instead of a new one, `PUT
   .../rules` replaces that response's whole rule set — it's a full
   replace, not a merge, so include the rules you want to keep

Don't silently overwrite an existing default response when the ask is to
*add* a case — duplicate it first (`POST .../responses/:responseId/duplicate`) if you want to branch from it.

### Update vs. delete

`PATCH` on a project/endpoint/response changes in place and keeps the same
id — prefer this over delete+recreate, since delete also drops
`bodyHistory` (the last 5 versions of a response body, visible via
`GET /public/endpoints/:endpointId`) and any rules attached to what you
removed.

### Other capabilities worth knowing about

- **Gradual mock-to-real cutover, per endpoint.** `proxyConfiguration` on
  `CreateEndpointRequest`/`UpdateEndpointRequest` takes `default` (follows
  the project setting), `useProxy` (always forward to the real API), or
  `useMock` (always serve the mock). Useful for switching one endpoint
  over to a real backend while the rest stay mocked, without touching
  anything else. The project-wide equivalent (`Project.useProxy` /
  `proxyUrl`) is dashboard-only — not settable through `UpdateProjectRequest`.
- **Response history for free.** `bodyHistory` on each response (via
  `GET /public/endpoints/:endpointId`) holds the last 5 versions with
  timestamps — check it before assuming an update call silently failed.
- **Non-JSON responses.** A `content-type` header in an endpoint's
  `headers` array (`application/xml`, `text/xml`, `application/pdf`,
  `text/csv` are the accepted values besides JSON) switches the whole
  endpoint's format. This is endpoint-wide, not per-response.
- **No account needed for trivial cases.** `GET /hub/catalog` (no auth)
  lists Mockfly's free public sample APIs — each with pagination and
  `_delay`/`_status` query params for quick error/latency testing. Skip
  the whole account-setup flow if a demo just needs *some* working mock,
  not a specific shape.
- **Team access is dashboard-only.** `Project.allowedUsers` is read-only
  through the API — there's no endpoint to grant a colleague access to a
  project. Sharing a project means sharing dashboard access, not an API
  call.

## Using with demo-data-generator

`demo-data-generator` produces one consolidated OpenAPI spec per demo at
`output/{group_name}/server/openapi/{group_name}_api.yaml`, meant to be
deployed as a custom FastAPI server on Render. That spec — plus the seed
data and magic test values that server implements — can be reproduced on
Mockfly in **one `import` call**, using the same `ImportEndpointResponse.
rules` mechanism from the general import workflow above. Only one step at
the end is genuinely manual, and one magic value can't be faithfully
reproduced at all.

**Requires a paid Mockfly plan.** Full replication needs several
responses per endpoint (one per seed record, plus magic values, plus the
auth check) — the free plan's 2-responses-per-endpoint cap makes this
impractical. On free, stop after the plain import and accept the gaps
described in "What this gets you" below.

### The procedure

1. **Find the seed data and the spec.** Look under
   `output/{group_name}/server/` for `seed_data.json` and
   `openapi/{group_name}_api.yaml` — that's the path the top-level
   generated-file tree in demo-data-generator's own SKILL.md documents.
   Its `references/mock-api-patterns.md` shows a slightly different
   internal path (`data/seed_data.json`) in an architecture example; if
   the first path doesn't exist, check the real output tree instead of
   assuming either is right.

2. **Build one `ImportProjectRequest` covering everything, then send it
   in a single call.** For each endpoint in the OpenAPI spec that looks
   something up by an identifier (account number, member ID, etc.),
   assemble its `responses` array in this order (order matters —
   Mockfly evaluates responses **last-match-wins**, confirmed against
   `https://mockfly.dev/docs/conditional-response-mock-api/`: when
   several rules match, the last one in the list wins):
   1. A default response with **no rules** — a generic not-found body,
      matching what the real server returns for an unknown identifier
   2. One response per seed record, each with a rule: the identifier
      param `equal` that record's value, and a body built from that
      record's actual fields
   3. The magic values (see below)
   4. The `X-API-Key` check, added **last** so it overrides everything
      above when it fires

   `POST /public/projects/import` (account key) with the whole thing —
   project, all endpoints, all responses, all rules, in one call.

3. **Magic values**, added after the seed responses in each endpoint's
   array:
   - `ERROR-TEST` → rule: identifier `equal` `"ERROR-TEST"` → response
     status 500
   - `DECLINED-TEST` → only on payment/write endpoints → rule on the
     relevant field `equal` `"DECLINED-TEST"` → a declined-payment body
   - `TIMEOUT-TEST` → **can't be faithfully reproduced.** There is no
     per-response delay field in the schema — `delay` exists only on
     `CreateEndpointRequest`/`ImportEndpoint`, i.e. the *whole endpoint*,
     not one response on it. Setting it would slow down every request to
     that endpoint, not just ones using `TIMEOUT-TEST`. Tell the user this
     up front rather than silently skipping it or silently slowing down
     the whole endpoint — let them choose.

4. **`X-API-Key` enforcement**, as a `RuleGroup` with `operator: "or"`:
   one condition with `source: "header"`, `property: "X-API-Key"`,
   `comparator: "notExists"`; another with the same source/property,
   comparator `"distinct"` (the schema's paired opposite of `equal"` —
   verify against the live spec before relying on this, it isn't spelled
   out explicitly), `value: "demo-api-key-{group_name}"` → response 401.

5. **Get the mock URL.** The import call's response is a `Project`
   object — read `slug` off it: the live mock is at
   `https://<slug>.mockfly.dev`.

6. **The one manual step**: point the demo's Stage 2 API-spec upload (or
   whatever config in Omilia Copilot names the live API base URL) at that
   URL instead of the Render deployment's. Nothing here has API access to
   Omilia Copilot itself, so this happens in the Copilot UI — same
   drag-and-drop step demo-data-generator's own instructions describe,
   pointed somewhere different.

### What this gets you vs. plain import

| | Import only | Full procedure above |
|---|---|---|
| Endpoint shapes | ✓ | ✓ |
| Seed data matches transcripts/documents | ✗ (generic schema defaults) | ✓ |
| `ERROR-TEST` / `DECLINED-TEST` work | ✗ | ✓ |
| `TIMEOUT-TEST` works | ✗ | ✗ — not reproducible per-response either way |
| `X-API-Key` enforced | ✗ | ✓ |
| Plan required | Free is fine | Paid |
| API calls | 1 | 1 (everything assembled into one `import` body) |
| Manual work | None | One config pointer in Copilot |

Tell the user up front whether they want the fast plain import or the
full procedure, and that `TIMEOUT-TEST` is a known gap either way.

## Reading Back State

Before creating or editing, prefer `GET /public/endpoints` /
`GET /public/endpoints/:endpointId` over assuming what's already there —
Mockfly projects are often edited by hand in the web app between Claude
Code sessions, so cached assumptions about existing endpoints can be stale.

## Related Skills

- **mockfly-api** — auth, full endpoint reference, curl examples, troubleshooting
- **mockfly-cli** — serve a pulled snapshot of a project locally, offline
