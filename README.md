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
Until you sign in, Claude Code reports an error at the end of each turn: that is the plugin's `Stop` hook, which calls the plugin's server and cannot reach it before you have signed in.

If you work in Claude Code, connect Mechaneion with the plugin and never as a claude.ai connector, because a claude.ai connector reaches its one project from every repository you open.
If you have added it as one, `/mcp` turns that connector off in the repository you run it in, and `"disableClaudeAiConnectors": true` in a repository's `.claude/settings.json` turns off every claude.ai connector Claude Code fetches there, not only Mechaneion's.

## Your tests and your claims

A claim reads as held by a test only once your repository's own checks have sent the list of its tests and their results.
Mechaneion ships no adapter for any test runner, so that step is your repository's own, and your agent writes it: until a list has been sent, the Mechaneion tools tell your agent how, in the answers it reads while tying claims to tests and as the first piece of work of the first task it starts.
They show it how to get the names and results out of vitest, jest, node:test, pytest and dotnet test, as text it adapts to your runner.
The step ends with one `curl` that sends the results to `https://app.mechaneion.com/report/<project id>/run` with a project token, minted on *Other / CI* under *Settings → Your agent* and held as your checks' secret; nothing is installed for it.
The plugin itself runs no tests and sends no test results.

## What it runs, sends and keeps

The only address the plugin contacts is its MCP server, `https://app.mechaneion.com/mcp`, over HTTPS.

- **Signing in** is OAuth 2.0 in your browser, started by Claude Code's `/mcp`, and Claude Code keeps the token it gets.
  The plugin reads no token, key or password from your environment or your files, and asks for none.
- **Every Mechaneion tool call** goes to that server, with the arguments the call names.
- **`scripts/repository.sh`** is the server's `headersHelper`: Claude Code runs it when it connects the server, from the plugin's own folder.
  It takes the session's project directory to be the working directory of the Claude Code process that runs it, read with `lsof` on macOS or from `/proc` on Linux, with `ps` naming each process and its parent so that a shell standing between them is passed over; it reads nothing else of any process.
  A directory given as its argument, or in `CLAUDE_PROJECT_DIR`, is used instead; the plugin's own `.mcp.json` passes neither.
  It runs `git remote get-url` there, on `origin` or else the first remote, and Claude Code sends what it prints as the `Mechaneion-Repository` header on every request to the server, the sign-in's included.
  It sends the remote's host and path only, such as `github.com/Acme/Alpha`: the scheme, any username or credential in the URL, and a trailing `.git` are left out.
  A repository with no remote is sent as `local:` and the full path of its git folder on your disk, a folder that is no repository as `dir:` and its full path, and a name with any character outside printable ASCII as its SHA-256 digest instead.
  Whenever it names the repository it also prints an empty `Mechaneion-Folder` header, so the folder below is not sent.
  When it cannot find the project directory it prints no header, and on Windows it never runs: Claude Code runs a helper through `cmd.exe`, which has no `sh`, so it logs that the helper did not return a valid value and connects without it.
  The `Mechaneion-Repository` header is how the server knows which of your projects a session is for.
- **The server's `Mechaneion-Folder` header** is the session's project folder, which Claude Code fills in from `${CLAUDE_PROJECT_DIR}` as the full path on your disk, such as `C:\Users\Ada\Alpha`.
  Claude Code sends it on every request to the server only when `scripts/repository.sh` named no repository, and the server then knows the session's repository by that folder: each worktree and each clone of a repository is a repository of its own there, asked about once.
  A folder whose path has a character Claude Code cannot put in a header, one above U+00FF, stops Claude Code connecting the server at all in a session `scripts/repository.sh` cannot name.
- **The server's `Mechaneion-Client` header** says `claude-code-plugin` on every request, and nothing else: it tells the server the call is the plugin's.
  A call from the plugin that names neither its repository nor its folder is answered with what went wrong and how to fix it, and reaches none of your projects.
- **A `SessionStart` hook** runs `sh` on `hooks/session-start.sh` through Claude Code's own shell, Git Bash on Windows, at each session's start, after `/clear` and after a compaction.
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
