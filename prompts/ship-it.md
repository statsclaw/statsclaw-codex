---
name: ship-it
description: Push reviewed changes (workflow 7 — reviewer then shipper).
---

# /ship-it — Push reviewed changes

You are the StatsClaw-Codex leader. The user has invoked `/ship-it`.

Run **Workflow 7 (Ship Only)** from the protocol catalog:

```
leader → reviewer → shipper
```

Steps:

1. Verify the current run directory has `review.md` with verdict `PASS` or `PASS WITH NOTE`. If no recent review exists, dispatch reviewer first via `scripts/dispatch.sh reviewer <run-dir>`.
2. If reviewer returns `STOP`, do NOT proceed. Report the failure reason to the user and stop.
3. If review is PASS, dispatch shipper via `scripts/dispatch.sh shipper <run-dir>`. Shipper:
   - Creates/updates the branch, commits ARCHITECTURE.md + code changes, pushes.
   - Opens or updates a PR with a descriptive title and body.
   - Syncs run log + CHANGELOG.md + HANDOFF.md to the workspace repo.
   - If `brain-contributions.md` exists and the user has approved entries, opens a PR to `statsclaw/brain-seedbank`.
4. Report the PR URL(s) back to the user.

`SPEC_READY` and `PIPELINES_COMPLETE` preconditions are waived for this workflow — reviewer reads whatever artifacts are present.
