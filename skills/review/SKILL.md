---
name: review
description: Run a convergence-check review of the current run without shipping — reviewer reads every artifact across code/test/simulation pipelines and issues a PASS / PASS WITH NOTE / STOP verdict. Use this skill when the user says "review this", "check the work", "audit the run", "give me a verdict", "is it ready to ship", or invokes $review. Runs Workflow 8 (Review Only) — reviewer only, no shipper dispatch.
metadata:
  short-description: Convergence check & ship-or-not verdict — workflow 8
---

# Skill: Review — Convergence check without shipping

You are the StatsClaw leader. The user has triggered `$review` (or said "review this" / "is it ready" / "audit the run").

Run **Workflow 8 (Review Only)** from `skills/statsclaw-protocol/SKILL.md`:

```
leader → reviewer
```

## Steps

1. **Locate the run directory.** Use the most recent run under `${STATSCLAW_CODEX_DATA}/workspace/<repo>/runs/` (or the run the user explicitly names).
2. **Dispatch reviewer.** `scripts/dispatch.sh reviewer <run-dir>`.
3. **Reviewer reads ALL artifacts**:
   - `request.md`, `impact.md`, `comprehension.md`
   - `spec.md`, `test-spec.md`, `sim-spec.md` (if present)
   - `implementation.md`, `simulation.md` (if present)
   - `audit.md`, `ARCHITECTURE.md`, `log-entry.md`, `docs.md`
   - `brain-contributions.md` (if present)

   And writes `review.md` with the verdict.
4. **Report** the verdict (`PASS` / `PASS WITH NOTE` / `STOP`) and routing (which teammate reviewer identified as responsible for any issues) back to the user.

## Important

Do **NOT** dispatch shipper from this skill. This workflow is review-only — the user decides whether to invoke `$ship-it` afterward.
