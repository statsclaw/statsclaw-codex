---
name: patrol
description: Scan and auto-fix open GitHub issues across a target repository using the StatsClaw 9-agent workflow. Use this skill whenever the user asks to "patrol issues", "triage and fix open issues", "sweep the issue tracker", "resolve bugs in <repo>", or invokes $patrol explicitly. The skill runs Workflow 4 (Issue Patrol) — it lists open issues, triages them, dispatches the planner → builder → tester → scriber → reviewer → shipper chain for each in-scope issue, opens PRs, and posts reply comments. Accepts arguments of the form `<owner/repo> [base-branch]` or a GitHub URL.
metadata:
  short-description: Issue patrol — scan, triage, auto-fix, PR, reply
---

# Skill: Patrol — Auto-triage and fix open GitHub issues

You are the StatsClaw leader. The user has triggered `$patrol` (or described a patrol-shaped task in natural language).

Run **Workflow 4 (Issue Patrol)** from `skills/statsclaw-protocol/SKILL.md`. The authoritative procedure lives in `skills/issue-patrol/SKILL.md` — load that file and follow it exactly.

## Quick summary (full details in skills/issue-patrol/SKILL.md)

1. Parse arguments: resolve `<repo>` to `owner/repo`. Accept GitHub URLs, `owner/name`, or bare repo name if unambiguous from workspace context.
2. Run the standard session-start gates (detect mode, acquire workspace, verify credentials). See `skills/credential-setup/SKILL.md`.
3. Create a patrol run directory under `${STATSCLAW_CODEX_DATA}/workspace/<repo>/runs/PATROL-<timestamp>/`.
4. **Scan phase** — `gh issue list --repo owner/repo --state open --limit 50`. Classify each into triage buckets (bug / feature / question / duplicate / out-of-scope) and write `patrol-triage.md`.
5. **Fix loop** — for each in-scope issue:
   - Create `issue-<number>/` sub-run directory.
   - Dispatch `planner → builder → tester → scriber → reviewer → shipper` via `scripts/dispatch.sh`.
   - Shipper pushes a branch, opens a PR that references the issue (`Fixes #N`), and posts a comment on the issue linking the PR.
6. **Report phase** — write `patrol-report.md` summarizing issues touched, PRs opened, issues skipped and why.

If the user supplies a `[base-branch]`, all PRs target that branch; otherwise default to the repo's default branch.

Patrol runs autonomously — no per-issue user confirmation. The only pause is HOLD when planner needs clarification.

**Before you start**, confirm the interpreted arguments (repo + base-branch) back to the user with a numbered-options question if anything is ambiguous.
