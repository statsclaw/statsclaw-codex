---
name: brain
description: Enable, disable, or inspect the StatsClaw shared brain — the cross-user knowledge system that lets agents read curated statistical knowledge and optionally contribute back. Use this skill when the user says "turn on brain", "enable brain mode", "turn off brain", "check brain status", "brain on", "brain off", or invokes $brain with on/off/status. Saves the setting to context.md and clones the brain repos if enabling. Full contribution lifecycle lives in skills/brain-sync.
metadata:
  short-description: Manage brain-mode on/off/status
---

# Skill: Brain — Manage Brain mode

You are the StatsClaw leader. The user has triggered `$brain` (or said something like "turn brain on").

Full protocol in `skills/brain-sync/SKILL.md`. Three actions:

## `$brain on` (or "enable", "connect", "turn on brain")

1. Set `BrainMode` to `"connected"` in `${STATSCLAW_CODEX_DATA}/workspace/<repo>/context.md` (or the clone-mode equivalent).
2. Clone `statsclaw/brain` into `${STATSCLAW_CODEX_DATA}/brain/` and `statsclaw/brain-seedbank` into `${STATSCLAW_CODEX_DATA}/brain-seedbank/` (or pull if already present).
3. Confirm to the user: "Brain mode ON — agents will now read `${STATSCLAW_CODEX_DATA}/brain/` at dispatch time, and noteworthy discoveries will be offered for contribution after each workflow."

## `$brain off` (or "disable", "isolated", "turn off brain")

1. Set `BrainMode` to `"isolated"` in `context.md`.
2. Do **NOT** delete the local brain clones — the user may re-enable later.
3. Confirm: "Brain mode OFF — agents will not read the shared brain, and nothing will be contributed."

## `$brain status` (or no argument)

1. Read `BrainMode` from `context.md`.
2. Report: current mode, local brain commit hash, local brain-seedbank commit hash, number of entries by category.

## Error handling

Brain repo unavailability (no network, no credentials) is a **warning, not a hard gate**. The workflow proceeds in isolated mode and leader tells the user why.
