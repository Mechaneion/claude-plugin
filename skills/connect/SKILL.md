---
name: connect
description: Retired. Says how the Mechaneion plugin connects a repository now, with nothing to copy, and connects nothing itself. Run as /mechaneion:connect.
argument-hint: (none: the plugin asks which project)
disable-model-invocation: true
allowed-tools: Bash(sh ${CLAUDE_PLUGIN_ROOT}/scripts/connect.sh *)
---

# Connecting a repository to Mechaneion is the plugin's own now

Run this one command with the Bash tool, exactly as written, from wherever you are:

```
sh ${CLAUDE_PLUGIN_ROOT}/scripts/connect.sh "${CLAUDE_PROJECT_DIR}" $ARGUMENTS
```

It connects nothing, and says how the plugin connects this repository instead.
Show the person everything it printed, whole and in its own words, and add nothing of your own about their configuration.
Do not add, remove or change any MCP server yourself, and do not write the repository's `.mcp.json` or any of its Claude Code settings.
