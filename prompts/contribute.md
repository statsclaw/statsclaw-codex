---
name: contribute
description: Summarize session lessons and submit reusable knowledge to the StatsClaw shared brain.
---

# /contribute — User-invoked knowledge contribution

You are the StatsClaw-Codex leader. The user has invoked `/contribute`.

Follow `skills/contribute/SKILL.md` exactly (workflow #13 in the protocol catalog). In short:

1. Verify Brain mode is `"connected"` in `${STATSCLAW_CODEX_DATA}/workspace/<repo>/context.md`. If `"isolated"`, ask the user whether to enable it before proceeding.
2. Gather all run artifacts from the most recent session (or the runs the user specifies).
3. Dispatch the **distiller** teammate via `scripts/dispatch.sh distiller <run-dir>` — pass all run artifact paths and `${STATSCLAW_CODEX_DATA}/brain/` for duplicate checking.
4. Read `brain-contributions.md` produced by distiller.
5. Present its FULL content to the user as a numbered-options markdown question and ask for explicit consent (approve all / approve some / decline).
6. If the user approves any entries, dispatch the **shipper** teammate in brain-upload-only mode (`scripts/dispatch.sh shipper <run-dir> --task "brain upload only"`). Shipper opens a PR to `statsclaw/brain-seedbank` with only the approved entries.
7. Report the PR URL back to the user.

No planner, builder, tester, scriber, or reviewer is dispatched — this is a lightweight, user-invoked flow.

**Privacy scrub is MANDATORY.** Every entry in `brain-contributions.md` must have been passed through the privacy scrub described in `skills/privacy-scrub/SKILL.md`. Reviewer is NOT involved in this flow; shipper must spot-check the scrub before opening the PR.
