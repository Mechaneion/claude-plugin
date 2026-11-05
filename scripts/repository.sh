#!/bin/sh
# Mechaneion's headersHelper for Claude Code: names the repository a session runs in, so the one Mechaneion address
# the plugin carries, https://app.mechaneion.com/mcp, knows which of the person's projects the session is for.
#
#   sh repository.sh <the session's project directory>
#
# Claude Code runs it when it connects the plugin's server — at a session's start and on every reconnect — from the
# plugin's own root, with ${CLAUDE_PROJECT_DIR} substituted as the argument, and sends what it prints as headers on
# every request to the server, the sign-in's token request among them. Measured on Claude Code 2.1.317.
#
# **The repository is named by its git remote**, because that is the one name every clone and every worktree of it
# share: a directory would make each worktree a stranger the server asks about again. `origin` first, then the first
# remote there is, written as host/path — the scheme, any user or credential in the URL, and a trailing .git left
# out, so `https://ada:secret@GitHub.com/Acme/Alpha.git` and `git@github.com:Acme/Alpha` are both
# `github.com/Acme/Alpha`. A repository with no remote is named by its git directory, which its worktrees share, and
# a directory that is no repository at all by itself.
#
# It always prints one JSON object and exits 0: Claude Code gives a helper ten seconds and connects without its
# headers when it fails, and then the server cannot tell the repository and says so.

dir="${1:-}"
[ -n "$dir" ] || dir=$(pwd)

remote=$(git -C "$dir" remote get-url origin 2>/dev/null || true)
if [ -z "$remote" ]; then
  first=$(git -C "$dir" remote 2>/dev/null | head -n 1)
  [ -z "$first" ] || remote=$(git -C "$dir" remote get-url "$first" 2>/dev/null || true)
fi

if [ -n "$remote" ]; then
  case "$remote" in
    *://*) named=$(printf '%s' "$remote" | sed -E 's#^[A-Za-z][A-Za-z0-9+.-]*://##; s#^[^@/]*@##') ;;
    # The scp-like form, `user@host:path`, whose colon is the path's start and never a port.
    *) named=$(printf '%s' "$remote" | sed -E 's#^[^@/]*@##; s#:#/#') ;;
  esac
  named=$(printf '%s' "$named" | sed -E 's#/+$##; s#\.git$##; s#/+$##')
  host=$(printf '%s' "${named%%/*}" | tr 'A-Z' 'a-z')
  case "$named" in
    */*) named="$host/${named#*/}" ;;
    *) named="$host" ;;
  esac
else
  common=$(cd "$dir" 2>/dev/null && git rev-parse --git-common-dir 2>/dev/null || true)
  if [ -n "$common" ]; then
    common=$(cd "$dir" && cd "$common" 2>/dev/null && pwd -P || printf '%s' "$common")
    named="local:${common%/.git}"
  else
    named="dir:$dir"
  fi
fi

# **A header carries printable ASCII and nothing else**, so a name with anything outside it is sent as its digest.
if printf '%s' "$named" | LC_ALL=C grep -q '[^ -~]'; then
  named="sha256:$(printf '%s' "$named" | shasum -a 256 2>/dev/null | cut -d ' ' -f 1)"
fi
escaped=$(printf '%s' "$named" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"Mechaneion-Repository":"%s"}\n' "$escaped"
exit 0
