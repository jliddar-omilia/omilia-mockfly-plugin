# Installing the Mockfly plugin

For anyone at Omilia who wants Claude Code to manage Mockfly mock APIs
directly. Takes about 5 minutes. No admin approval needed — this plugin
doesn't use an MCP server, so it isn't affected by any MCP allowlist policy.

## Prerequisites

- Claude Code CLI installed and working (`claude --version` runs)
- A terminal (macOS: Applications → Utilities → Terminal)

## 1. Install the plugin

Open a terminal and run:

```bash
claude plugin marketplace add jliddar-omilia/omilia-mockfly-plugin
claude plugin install mockfly@omilia-mockfly-plugin
```

**What you should see:** two lines ending in
`✔ Successfully added marketplace...` and
`✔ Successfully installed plugin: mockfly@omilia-mockfly-plugin (scope: user)`.

This installs it for every project on your machine, once.

## 2. Get your Mockfly API keys

If you don't already have a Mockfly account:

1. Go to `mockfly.dev` and sign up (free plan, no credit card).
2. Create a project in the dashboard (or skip this — Claude can create one
   for you once step 3 is done).

Then get two keys:

1. **Account API key** — `app.mockfly.dev/api-keys`
2. **Project API key** — open a project, find it in that project's settings page

## 3. Set your keys as environment variables

1. Find out which shell you use:
   ```bash
   echo $SHELL
   ```
   Ends in `zsh` → edit `~/.zshrc`. Ends in `bash` → edit `~/.bash_profile`.
   The rest of this guide says `~/.zshrc`; swap in the other name if needed.

2. Open the file:
   ```bash
   nano ~/.zshrc
   ```

3. Move to the end of the file and add these two lines, with your real
   keys in place of the placeholders:
   ```bash
   export MOCKFLY_ACCOUNT_API_KEY="paste_your_account_key_here"
   export MOCKFLY_API_KEY="paste_your_project_key_here"
   ```

4. Save: **Control+O**, then **Enter**. Exit: **Control+X**.

5. Close the terminal window and open a new one (env vars only load in
   *new* terminal sessions).

## 4. Verify

In the new terminal:

```bash
echo $MOCKFLY_ACCOUNT_API_KEY
echo $MOCKFLY_API_KEY
```

**What you should see:** both keys printed back, not blank lines. If
either is blank, redo step 3 — it didn't save correctly.

## 5. Try it

```bash
claude
```

Then, inside Claude Code:

```
list my mockfly projects
```

**What you should see:** a table of your Mockfly projects (or an empty
list if you haven't created one yet — ask Claude to create one).

## If something goes wrong

- **401 / "key" errors**: re-check step 4 — the env var isn't loaded in
  the terminal you're running Claude Code from.
- **403 errors**: you mixed up the account key and the project key — see
  the table in the `mockfly-api` skill for which key goes with which
  operation.
- **429 errors**: free-plan limit (1 project, 4 endpoints/project, 2
  responses/endpoint) — expected, not a bug.
- Anything else: ask Claude Code directly — the `mockfly-api` skill's
  troubleshooting reference covers this, or ping Jimmy Liddar
  (jliddar@omilia.com).

**Never** paste your API keys into a chat with Claude, a Slack message,
or anywhere else that gets logged. They only need to live in your shell
config file from step 3.
