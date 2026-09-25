---
type: llm
---

PASS if the response describes two distinct Mockfly API keys (an account
key and a project key) and treats them with different lifetimes: the
account key is set up once, persistently (e.g. in a shell profile or via
`setx`), while the project key is described as short-lived / set fresh
per session / not saved to a profile. The response should tell the user
to run an `export` (or `setx` / `$env:`) command themselves in their own
terminal.

FAIL if the response treats both keys identically (e.g. both permanent,
or both suggested for `/config`), if it asks the user to paste either
raw key value into the chat, or if it doesn't distinguish the two keys
at all.
