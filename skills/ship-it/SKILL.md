---
name: ship-it
description: Commit, push, and open a pull request for the reviewed changes in the current run — plus sync the workspace log and, if applicable, open a brain-seedbank PR. Use this skill whenever the user says "ship it", "push the changes", "open a PR", "commit and push", "send it to main", "release this", or invokes $ship-it. Runs Workflow 7 (Ship Only) — dispatches reviewer first if no recent review exists, aborts on STOP verdicts, and only ships on PASS or PASS WITH NOTE.
metadata:
  short-description: Ship reviewed changes — workflow 7
---

# Skill: Ship-it — Push reviewed changes

You are the StatsClaw leader. The user has triggered `$ship-it` (or said "ship it" / "push the changes" / "open a PR").

Run **Workflow 7 (Ship Only)** from `skills/statsclaw-protocol/SKILL.md`:

```
leader → reviewer → shipper
```

## Steps

1. **Locate the run directory.** Use the most recent run under `${STATSCLAW_CODEX_DATA}/workspace/<repo>/runs/` (or `.repos/workspace/<repo>/runs/` in clone mode).
2. **Verify review.** Check the run directory for `review.md` with verdict `PASS` or `PASS WITH NOTE`. If no recent review exists, dispatch reviewer first: `scripts/dispatch.sh reviewer <run-dir>`.
3. **Handle STOP.** If reviewer returns `STOP`, do NOT proceed. Report the failure reason to the user and stop. Do not attempt to fix the failure directly — that's a separate workflow invocation.
4. **Dispatch shipper.** On PASS or PASS WITH NOTE, dispatch shipper: `scripts/dispatch.sh shipper <run-dir>`. Shipper:
   - Creates/updates the branch, commits ARCHITECTURE.md + code changes, pushes.
   - Opens or updates a PR with a descriptive title and body referencing the spec.
   - Syncs run log + CHANGELOG.md + HANDOFF.md to the workspace repo.
   - If `brain-contributions.md` exists and the user has approved entries, opens a PR to `statsclaw/brain-seedbank`.
5. **Report.** Report the PR URL(s) back to the user.

## Preconditions

`SPEC_READY` and `PIPELINES_COMPLETE` are **waived** for this workflow — reviewer reads whatever artifacts are present. But CREDENTIALS is a hard gate (see `skills/credential-setup/SKILL.md`).
