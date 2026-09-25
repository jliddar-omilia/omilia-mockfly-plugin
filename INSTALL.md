# Installing the Mockfly plugin

For anyone at Omilia who wants Claude Code to manage Mockfly mock APIs
directly. Takes about 5 minutes. No admin approval needed — this plugin
doesn't use an MCP server, so it isn't affected by any MCP allowlist policy.

Pick your OS below: [macOS / Linux](#macos--linux) or [Windows](#windows).

## Prerequisites

- Claude Code CLI installed and working (`claude --version` runs)
- **Windows only:** [Git for Windows](https://git-scm.com/downloads/win)
  installed. Not required to run Claude Code, but it gives Claude Code a
  real `curl` (via Git Bash) instead of PowerShell's `curl` alias, which
  is actually `Invoke-WebRequest` and doesn't understand the same flags —
  this plugin's skills use real `curl` syntax. Without Git for Windows,
  some commands may not work as written.

---

## macOS / Linux

### 1. Install the plugin

Open a terminal and run:

```bash
claude plugin marketplace add jliddar-omilia/omilia-mockfly-plugin
claude plugin install mockfly@omilia-mockfly-plugin
```

**What you should see:** two lines ending in
`✔ Successfully added marketplace...` and
`✔ Successfully installed plugin: mockfly@omilia-mockfly-plugin (scope: user)`.

This installs it for every project on your machine, once.

### 2. Get your Mockfly API keys

If you don't already have a Mockfly account:

1. Go to `mockfly.dev` and sign up (free plan, no credit card).
2. Create a project in the dashboard (or skip this — Claude can create one
   for you once step 3 is done).

Then get two keys:

1. **Account API key** — `app.mockfly.dev/api-keys`
2. **Project API key** — open a project, find it in that project's settings page

### 3. Set your keys as environment variables

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

### 4. Verify

In the new terminal:

```bash
echo $MOCKFLY_ACCOUNT_API_KEY
echo $MOCKFLY_API_KEY
```

**What you should see:** both keys printed back, not blank lines. If
either is blank, redo step 3 — it didn't save correctly.

### 5. Try it

```bash
claude
```

Then, inside Claude Code:

```
list my mockfly projects
```

**What you should see:** a table of your Mockfly projects (or an empty
list if you haven't created one yet — ask Claude to create one).

---

## Windows

Works whether you run Claude Code natively (PowerShell) or inside WSL.
**If you're using WSL**, ignore this section and follow the
[macOS / Linux](#macos--linux) steps instead — inside WSL you have a real
Linux shell (bash/zsh), so those instructions apply exactly as written.

The steps below are for **native Windows, in PowerShell**. Open PowerShell
(Start menu → search "PowerShell"). Your prompt looks like
`PS C:\Users\YourName>`.

### 1. Install the plugin

```powershell
claude plugin marketplace add jliddar-omilia/omilia-mockfly-plugin
claude plugin install mockfly@omilia-mockfly-plugin
```

**What you should see:** two lines ending in
`✔ Successfully added marketplace...` and
`✔ Successfully installed plugin: mockfly@omilia-mockfly-plugin (scope: user)`.

### 2. Get your Mockfly API keys

Same as macOS/Linux:

1. Sign up at `mockfly.dev` if you don't have an account (free plan, no
   credit card), and optionally create a project.
2. Get your **account API key** from `app.mockfly.dev/api-keys`.
3. Get your **project API key** from a project's settings page.

### 3. Set your keys as environment variables

In PowerShell, run these two commands with your real keys in place of the
placeholders:

```powershell
setx MOCKFLY_ACCOUNT_API_KEY "paste_your_account_key_here"
setx MOCKFLY_API_KEY "paste_your_project_key_here"
```

**What you should see:** `SUCCESS: Specified value was saved.` twice.
`setx` saves the variable permanently for your Windows user account — you
don't need to edit any profile file.

Close this PowerShell window and open a new one (`setx` only takes effect
in *new* windows, not the one you ran it from).

### 4. Verify

In the new PowerShell window:

```powershell
echo $env:MOCKFLY_ACCOUNT_API_KEY
echo $env:MOCKFLY_API_KEY
```

**What you should see:** both keys printed back, not blank lines. If
either is blank, redo step 3.

### 5. Try it

```powershell
claude
```

Then, inside Claude Code:

```
list my mockfly projects
```

**What you should see:** a table of your Mockfly projects (or an empty
list if you haven't created one yet — ask Claude to create one).

---

## If something goes wrong

- **401 / "key" errors**: the env var isn't loaded in the terminal you're
  running Claude Code from — re-check the verify step for your OS.
- **403 errors**: you mixed up the account key and the project key — see
  the table in the `mockfly-api` skill for which key goes with which
  operation.
- **429 errors**: free-plan limit (1 project, 4 endpoints/project, 2
  responses/endpoint) — expected, not a bug, unless you're on a paid plan.
- **On Windows, curl-based commands fail or behave oddly**: install
  [Git for Windows](https://git-scm.com/downloads/win) so Claude Code uses
  a real `curl` via Git Bash instead of the PowerShell `curl` alias.
- Anything else: ask Claude Code directly — the `mockfly-api` skill's
  troubleshooting reference covers this, or ping Jimmy Liddar
  (jliddar@omilia.com).

**Never** paste your API keys into a chat with Claude, a Slack message,
or anywhere else that gets logged. They only need to live in your
environment variables from step 3.
