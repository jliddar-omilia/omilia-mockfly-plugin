---
type: llm
---

PASS if the explanation says the raw YAML file is NOT sent directly to
`POST /public/projects/import` — that Mockfly's public API only accepts
its own `{project, endpoints, responses}` JSON shape, and that the OpenAPI
spec's paths/operations need to be converted into that shape first (each
operation becoming an endpoint with at least one response derived from
its schema).

FAIL if the explanation claims or implies the raw OpenAPI YAML/file
content can be POSTed directly as the import request body, or treats
the public API's import as equivalent to the dashboard's drag-and-drop
file upload.
