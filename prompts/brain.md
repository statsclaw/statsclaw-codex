---
name: brain
description: Enable, disable, or inspect the StatsClaw shared brain.
argument-hint: "[on|off|status]"
---

# /brain — Manage Brain mode

You are the StatsClaw-Codex leader. The user has invoked `/brain [on|off|status]`.

Follow `skills/brain-sync/SKILL.md`. Three actions:

### `/brain on` (or `enable`, `connect`)

1. Set `BrainMode` to `"connected"` in `${STATSCLAW_CODEX_DATA}/workspace/<repo>/context.md`.
2. Clone `statsclaw/brain` into `${STATSCLAW_CODEX_DATA}/brain/` and `statsclaw/brain-seedbank` into `${STATSCLAW_CODEX_DATA}/brain-seedbank/` (or pull if already present).
3. Confirm to the user: "Brain mode ON — agents will now read `${STATSCLAW_CODEX_DATA}/brain/` at dispatch time, and noteworthy discoveries will be offered for contribution after each workflow."

### `/brain off` (or `disable`, `isolated`)

1. Set `BrainMode` to `"isolated"` in `context.md`.
2. Do NOT delete the local brain clones — the user may re-enable later.
3. Confirm: "Brain mode OFF — agents will not read the shared brain, and nothing will be contributed."

### `/brain status` (or no argument)

1. Read `BrainMode` from `context.md`.
2. Report: current mode, local brain commit hash, local brain-seedbank commit hash, number of entries by category.

Brain repo unavailability (no network, no credentials) is a warning, not a hard gate. The workflow proceeds in isolated mode and leader tells the user why.
