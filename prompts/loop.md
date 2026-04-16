---
name: loop
description: Run a prompt or slash command on a recurring interval (default 10m).
argument-hint: "[interval] <inner-prompt>"
---

# /loop — Scheduled recurring execution

You are the StatsClaw-Codex leader. The user has invoked `/loop <interval> <inner-prompt>` or `/loop <inner-prompt>` (default interval 10m).

Parse the user's arguments:

1. First token matches `/^[0-9]+(d|h|m|s)+$/` → that is the `interval`, rest is the `inner-prompt`.
2. Otherwise → `interval = 10m`, entire argument string is `inner-prompt`.

Examples:

| User types | Parsed |
| --- | --- |
| `/loop 30m patrol fect issues on cfe` | interval=30m, inner="patrol fect issues on cfe" |
| `/loop monitor fect issues` | interval=10m, inner="monitor fect issues" |
| `/loop 5m /review` | interval=5m, inner="/review" |

Then invoke:

```bash
bash ${STATSCLAW_CODEX_ROOT}/scripts/loop.sh <interval> "<inner-prompt>"
```

The script runs the inner prompt on each tick via `codex exec --profile statsclaw-leader --full-auto "<inner-prompt>"`. It continues until the user kills it (Ctrl-C) or the inner command prints a line matching `^LOOP:STOP$` on stdout.

**Do NOT implement polling with `sleep` inside the main session.** The loop runs as a child process managed by `scripts/loop.sh`.
