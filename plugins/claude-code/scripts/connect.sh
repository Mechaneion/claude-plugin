#!/bin/sh
# /mechaneion:connect — RETIRED (task M9S5K6). It connected a repository to a project by its id, with Claude Code's
# own `claude mcp add --scope local`; the plugin now carries its own server, at the one address with no project in it,
# https://app.mechaneion.com/mcp, which asks the person which of their projects each repository is for. So this
# refuses, loudly, with the way that replaced it, and adds nothing: a second server for the same project would list
# every Mechaneion tool twice.
#
# Exits 1, always.

printf '%s\n' \
  "Nothing was connected: /mechaneion:connect is retired, and the plugin connects itself now, with no project id to copy." \
  "Sign in once with /mcp, choosing plugin:mechaneion:mechaneion and Authenticate (or run claude mcp login plugin:mechaneion:mechaneion in your shell): your browser opens Mechaneion, which asks which of your projects this repository is for, or makes a new one. Every other repository asks once, the first time a Mechaneion tool is called there, with a link to the same question." \
  "A mechaneion server the old command added to this repository reaches the same project a second time once the plugin's does: claude mcp remove mechaneion --scope local takes it away."
exit 1
