# Mechaneion for Claude Code

Mechaneion keeps what a product claims to do, the rules it obeys, and the work in flight, for the people building it and for their agents.
This plugin connects Claude Code to it: every session in a repository reaches that repository's Mechaneion project, is told before a turn ends what it would be walking away from, and can ask what needs doing next.
You need a Mechaneion account, from https://mechaneion.com.

## Install

Install it for yourself, which turns it on in every repository you open:

```
claude plugin install mechaneion --marketplace Mechaneion/claude-plugin --scope user
```

Then sign in once: in Claude Code run `/mcp`, choose `plugin:mechaneion:mechaneion` and *Authenticate*.
Your browser opens app.mechaneion.com, which signs you in and asks which of your projects the repository is for, or makes a new one.
Every other repository asks once, the first time a Mechaneion tool is called there.

## What it runs, sends and keeps

The only address the plugin contacts is its MCP server, `https://app.mechaneion.com/mcp`, over HTTPS.

- **Signing in** is OAuth 2.0 in your browser, started by Claude Code's `/mcp`, and Claude Code keeps the token it gets.
  The plugin reads no token, key or password from your environment or your files, and asks for none.
- **Every Mechaneion tool call** goes to that server, with the arguments the call names.
- **`scripts/repository.sh`** is the server's `headersHelper`: Claude Code runs it when it connects the server, from the plugin's own folder.
  It takes the session's project directory to be the working directory of the Claude Code process that runs it, read with `lsof` on macOS or from `/proc` on Linux, with `ps` naming each process and its parent so that a shell standing between them is passed over; it reads nothing else of any process.
  A directory given as its argument, or in `CLAUDE_PROJECT_DIR`, is used instead; the plugin's own `.mcp.json` passes neither.
  It runs `git remote get-url` there, on `origin` or else the first remote, and Claude Code sends what it prints as the `Mechaneion-Repository` header on every request to the server, the sign-in's included.
  When it cannot find the project directory it sends no header, and the server answers as it does a session that named no repository.
  It sends the remote's host and path only, such as `github.com/Acme/Alpha`: the scheme, any username or credential in the URL, and a trailing `.git` are left out.
  A repository with no remote is sent as `local:` and the full path of its git folder on your disk, a folder that is no repository as `dir:` and its full path, and a name with any character outside printable ASCII as its SHA-256 digest instead.
  That header is how the server knows which of your projects a session is for.
- **A `SessionStart` hook** runs `hooks/session-start.sh` at each session's start, after `/clear` and after a compaction.
  It reads the hook's input from Claude Code, or `CLAUDE_CODE_SESSION_ID` when the input names no session, and prints the session's id into the session's context with a line on how to sign in.
  It contacts nothing and writes nothing.
- **A `Stop` hook** calls the server's `commissions_walking_away` tool at each turn's end, with the session's id and whether a `Stop` hook is already running.
  When the session holds Mechaneion work nobody has begun, or project news it has not read and has not been told of, the answer keeps the turn going, once for each, with what it would be walking away from; otherwise it answers nothing.
- **`/mechaneion:what-needs-doing`** calls three of the server's read-only tools, `commissions_bearings`, `commissions_board` and `owed_list`, and answers from what they say.
- **`/mechaneion:connect`** is retired: it runs `scripts/connect.sh`, which prints how the plugin connects a repository now and exits 1.

The plugin keeps nothing on your machine; Claude Code keeps the sign-in.
What Mechaneion keeps of what the server is sent, where it is kept and for how long, is its privacy policy.

## Privacy and support

Privacy policy: https://mechaneion.com/privacy.
Questions and support: hello@mechaneion.com.

## Source and licence

The plugin is published to github.com/Mechaneion/claude-plugin from Mechaneion's own repository, where every change to it is made.
It is licensed under the Apache License 2.0.
