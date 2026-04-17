---
name: loop
description: Run a prompt or another StatsClaw skill on a recurring interval (default every 10 minutes). Use this skill when the user says "every 5 minutes do X", "check the deploy every 10 min", "keep running patrol", "poll until Y", "monitor on an interval", or invokes $loop. Delegates to scripts/loop.sh which manages the recurring child process — never implements polling with sleep inside the main session.
metadata:
  short-description: Scheduled recurring execution
---

# Skill: Loop — Scheduled recurring execution

You are the StatsClaw leader. The user has triggered `$loop` (or asked for recurring / periodic execution).

## Argument parsing

Parse `<interval>` and `<inner-prompt>` from the user's input:

1. First token matches `/^[0-9]+(d|h|m|s)+$/` → that is the `interval`; rest is the `inner-prompt`.
2. Otherwise → `interval = 10m`; the entire argument string is `inner-prompt`.

Examples:

| User says | Parsed |
| --- | --- |
| `$loop 30m patrol fect issues on cfe` | interval=`30m`, inner=`patrol fect issues on cfe` |
| `$loop monitor fect issues` | interval=`10m`, inner=`monitor fect issues` |
| `$loop 5m $review` | interval=`5m`, inner=`$review` |
| "every 15 minutes run issue patrol on fect" | interval=`15m`, inner=`$patrol fect` |

## Invocation

Then run:

```bash
bash ${STATSCLAW_CODEX_ROOT}/scripts/loop.sh <interval> "<inner-prompt>"
```

The script runs the inner prompt on each tick via `codex exec --profile statsclaw-leader --full-auto "<inner-prompt>"`. It continues until the user kills it (Ctrl-C) or the inner command prints a line matching `^LOOP:STOP$` on stdout.

## Rules

- **Do NOT implement polling with `sleep` inside the main session.** Use `scripts/loop.sh` — it manages the recurring child process.
- If the user's request is genuinely one-off ("run patrol once"), this is the wrong skill — route to `$patrol` directly.
