#!/bin/sh
# Mechaneion's SessionStart hook for Claude Code (COMMISSIONS 3.12 · Listening needs no setup).
#
# Claude Code adds what this prints to the session's context, at every session's start, after a /clear and after a
# compaction alike. It tells the session its own conversation id, which commissions_hello takes as `conversation`.
#
# THAT ID IS THE WHOLE OF HOW THE TURN'S-END HOOK FINDS A SESSION on the remote server. The server runs beside the
# project's page and keeps no process per conversation, so nothing there can tell which session a request is; the
# plugin's Stop hook hands the server the same id Claude Code hands it, and the server finds the session that said
# hello naming it.
#
# The id is the hook's own `session_id`, read off standard input, or CLAUDE_CODE_SESSION_ID, which Claude Code sets to
# the same id in every hook it runs. It always exits 0: a SessionStart hook that fails is reported at the start of
# every session.

input=$(cat 2>/dev/null || true)
conversation=$(printf '%s' "$input" | tr -d '\n\r' | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
[ -n "$conversation" ] || conversation="${CLAUDE_CODE_SESSION_ID:-}"

unconnected="If no Mechaneion tools are in your list, the plugin's server is not signed in: the person signs in once, with /mcp, choosing plugin:mechaneion:mechaneion and Authenticate, and until then Claude Code reports the plugin's turn's-end hook as an error at each turn's end. A repository the person has not yet said a project for answers every Mechaneion call with a link: show it to them whole, since opening it asks which of their projects this repository is for, or makes a new one."

if [ -z "$conversation" ]; then
  printf '%s\n' "Mechaneion: Claude Code named no id for this conversation, so call commissions_hello without a conversation. The plugin's turn's-end hook then cannot find your session, and what you would walk away from arrives on your next Mechaneion answer instead (COMMISSIONS 3.12). $unconnected"
  exit 0
fi

printf '%s\n' "Mechaneion: this conversation's id is $conversation. When you call commissions_hello, pass it as \"conversation\": that is how the Mechaneion plugin's turn's-end hook finds your session and says, before your turn ends, what you would be walking away from (COMMISSIONS 3.12). $unconnected"
exit 0
