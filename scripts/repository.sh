#!/bin/sh
# Mechaneion's headersHelper for Claude Code: names the repository a session runs in, so the one Mechaneion address
# the plugin carries, https://app.mechaneion.com/mcp, knows which of the person's projects the session is for.
#
#   sh repository.sh [<the session's project directory>]
#
# Claude Code runs it when it connects the plugin's server — at a session's start and on every reconnect — and sends
# what it prints as headers on every request to the server, the sign-in's token request among them.
#
# **The session's project directory is the first of these there is:**
#
#   1. its first argument, which the plugin's .mcp.json passed as "${CLAUDE_PROJECT_DIR}" up to version 0.2.2;
#   2. CLAUDE_PROJECT_DIR in its environment, should Claude Code ever put it there;
#   3. the working directory of the Claude Code process that runs it, read with lsof on macOS and from /proc on Linux;
#   4. none, and then it prints {}: Claude Code sends no Mechaneion-Repository header, and the server answers the
#      session as one that named no repository.
#
# **Never its own working directory**: Claude Code runs a plugin's helper from the plugin's root, so `pwd` here is
# the plugin and never the project, and a plugin root inside a clone would send that clone's name for the session's.
#
# **Why the third, which is undocumented**: Anthropic's plugin directory refuses a command the plugin loader runs that
# names any variable but ${CLAUDE_PLUGIN_ROOT} (its "Command path can't be followed" finding, on the plugin published
# at a617d63), so the documented way, `sh "${CLAUDE_PLUGIN_ROOT}/scripts/repository.sh" "${CLAUDE_PROJECT_DIR}"`,
# cannot be listed there. Measured on Claude Code 2.1.318, with a probe plugin loaded by --plugin-dir: the helper's
# working directory is the plugin's root; its environment adds CLAUDE_PLUGIN_ROOT, CLAUDE_CODE_MCP_SERVER_NAME and
# CLAUDE_CODE_MCP_SERVER_URL and nothing that names the project; and its shell's parent is the claude process, whose
# working directory is the session's project. Claude Code's own documentation of MCP servers says the first two: a
# plugin's helper runs in "The plugin's root directory", and "Claude Code sets these environment variables when
# executing the helper", CLAUDE_CODE_MCP_SERVER_NAME, CLAUDE_CODE_MCP_SERVER_URL and CLAUDE_PLUGIN_ROOT, while
# "${CLAUDE_PROJECT_DIR} to the stable project root" is substituted in a plugin server's "url, headers, and
# headersHelper". That the parent is Claude Code, and where Claude Code's process stands, it says nowhere. **Should the
# directory stop refusing ${CLAUDE_PROJECT_DIR} in a headersHelper, the documented form comes back**, as the argument
# the first source reads.
#
# A shell standing between Claude Code and this script stands in this script's own working directory, so an ancestor
# that is a shell standing here is passed over for its parent, four ancestors at most; any other ancestor's directory
# is taken, Claude Code's when it was started in the plugin's own folder among them.
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
[ -n "$dir" ] || dir="${CLAUDE_PROJECT_DIR:-}"

if [ -z "$dir" ]; then
  here=$(pwd -P 2>/dev/null || pwd)
  pid=$PPID
  looked=0
  while [ "$looked" -lt 4 ] && [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
    looked=$((looked + 1))
    if [ -d "/proc/$pid" ]; then
      stands=$(readlink "/proc/$pid/cwd" 2>/dev/null || true)
    else
      stands=$(PATH="$PATH:/usr/sbin" lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -n 1)
    fi
    [ -n "$stands" ] || break
    case $(ps -o comm= -p "$pid" 2>/dev/null | sed 's#^-##; s#.*/##') in
      sh | bash | dash | zsh | ksh | mksh | ash | busybox)
        if [ "$stands" = "$here" ]; then
          pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
          continue
        fi
        ;;
    esac
    dir=$stands
    break
  done
fi

if [ -z "$dir" ]; then
  printf '{}\n'
  exit 0
fi

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
