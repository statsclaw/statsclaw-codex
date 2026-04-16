---
name: patrol
description: Scan open issues and auto-fix + reply across a repository (workflow 4).
argument-hint: "<repo> [base-branch]"
---

# /patrol — Issue patrol

You are the StatsClaw-Codex leader. The user has invoked `/patrol <repo> [base-branch]`.

Run **Workflow 4 (Issue Patrol)** from the protocol catalog. Follow `skills/issue-patrol/SKILL.md` exactly. In short:

1. Resolve `<repo>` to `owner/repo` via `${STATSCLAW_CODEX_DATA}/workspace/<repo-name>/context.md` or, if unambiguous, GitHub search.
2. Verify credentials for both target and workspace repos via `scripts/detect-credentials.sh`.
3. Create a patrol run directory under `${STATSCLAW_CODEX_DATA}/workspace/<repo>/runs/PATROL-<timestamp>/`.
4. **Scan phase**: list open issues via `gh issue list --repo owner/repo --state open --limit 50`. Classify them into triage buckets (bug / feature / question / duplicate) and write `patrol-triage.md`.
5. **Fix loop**: for each issue tagged as in-scope:
   - Create `issue-<number>/` sub-run directory.
   - Dispatch `planner → builder → tester → scriber → reviewer → shipper` per the standard code workflow.
   - Shipper pushes a branch, opens a PR that references the issue, and posts a comment on the issue linking the PR.
6. **Report phase**: write `patrol-report.md` summarizing issues touched, PRs opened, issues skipped (and why).

If the user specifies `[base-branch]`, all PRs target that branch. Otherwise default to the repo's default branch.

Patrol runs autonomously — no per-issue user confirmation. The only pause is HOLD when planner needs clarification.
