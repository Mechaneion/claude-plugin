---
name: what-needs-doing
description: Answers in a few lines what in this repository's Mechaneion project needs doing next and who each thing waits on, read from the project's own Mechaneion tools. Use when the person asks what needs doing, what is next, what is waiting on them, or where the project stands.
allowed-tools: mcp__plugin_mechaneion_mechaneion__commissions_bearings mcp__plugin_mechaneion_mechaneion__commissions_board mcp__plugin_mechaneion_mechaneion__owed_list
---

# What needs doing

Answer only from what Mechaneion's tools say now: never from memory, from the repository's files, or from a guess.
The three calls below are reads and write nothing.

1. Call `commissions_bearings`, with `"session"` set to your session key if `commissions_hello` gave you one in this conversation, and with nothing otherwise.
   It says how many commissions are in each of the board's buckets, how many wait on the person, what your session holds, and its one suggested next pick.
2. Call `commissions_board` with `{"buckets": ["FOR YOU", "WORKING", "NOT LANDED", "TEST FAILING", "TEST OWED", "NO VERDICT", "CLAIMS IN THE WAY", "RULING TO WRITE", "PART DONE", "NOT STARTED", "STALLED", "CAN'T BE TOLD"]}`: every bucket but DONE.
   Each line is a commission, the bucket it is in and why, and who holds it.
3. Call `owed_list` with `{}`: the decisions the person put off and has not ruled yet.

Then answer the person in a few lines, at most one line for each thing and the most pressing first: what holds up work, then what waits on them, then work nobody has begun.
Each line says what the thing is by its own words, as the tools gave them — a commission by its title, a decision by its words — and never by its key alone.
Each line says who it waits on, in these words:

- **waits on you** — a commission in FOR YOU, which the board names with the one act it waits on you for, and every decision `owed_list` lists;
- **waits on an agent** — a commission in any other bucket but DONE, with who holds it when the board names a holder, and "nobody has taken it" when it names none;
- **being worked** — a commission in WORKING, with who holds it.

End with the bearings' suggested next pick, in its own words.
If a tool says something could not be read, say that line too, so an absence is never read as nothing to do.

If a tool answers that this repository is not linked to a Mechaneion project yet, show the person the link it gives, whole: opening it asks which of their projects this repository is for, or makes a new one, and then ask again.
If none of these tools is in your list, the plugin's Mechaneion server is not connected in this session.
Say so, and say what the person does about it: sign in once with `/mcp`, choosing `plugin:mechaneion:mechaneion` and Authenticate, or `claude mcp login plugin:mechaneion:mechaneion` in their shell.
