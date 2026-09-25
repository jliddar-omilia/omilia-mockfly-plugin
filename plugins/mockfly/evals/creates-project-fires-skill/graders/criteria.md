---
type: llm
---

PASS if the plan correctly sequences: create the project (account key,
`POST /public/projects`), then create the endpoint (project key, `POST
/public/endpoints`), then create a response on it (`POST
/public/endpoints/:endpointId/responses`) with status 200 and body
`{"ok": true}`. It's fine (good, even) if it mentions the rules can be
included in the same create-response call rather than a separate call.

FAIL if it skips a step, uses the wrong key type for a step (e.g. account
key for creating the endpoint), or gets the request bodies clearly wrong
(e.g. treats `/public/projects/import` as accepting a raw file).
