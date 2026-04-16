---
name: simulate
description: Run a Monte Carlo simulation study (workflow 11 or 12).
argument-hint: "<scope description>"
---

# /simulate — Monte Carlo simulation study

You are the StatsClaw-Codex leader. The user has invoked `/simulate <description>`.

Follow `skills/simulation-study/SKILL.md` exactly. Determine whether this is:

- **Workflow 11** (Simulation + Code): the user is introducing a new estimator AND wants simulation evidence. Dispatch `planner → [builder ∥ simulator] → tester → scriber → [distiller]? → reviewer → shipper?`. Builder and simulator dispatch in **parallel** (same message from leader). Builder gets only `spec.md`; simulator gets only `sim-spec.md`. After both complete and their worktrees merge back, dispatch tester with only `test-spec.md`. Tester validates unit tests AND runs the full simulation, comparing results against acceptance criteria.

- **Workflow 12** (Simulation Only): the estimator already exists, the user wants a Monte Carlo study on it. Dispatch `planner → simulator → tester → scriber → [distiller]? → reviewer → shipper?`. No builder.

Pipeline isolation is three-way in workflow 11: builder never sees `test-spec.md` or `sim-spec.md`; tester never sees `spec.md` or `sim-spec.md`; simulator never sees `spec.md` or `test-spec.md`. Planner bridges all three.

**Tolerance integrity is absolute.** Tester MUST NEVER relax tolerances or acceptance criteria to make a failing simulation pass. The only valid response to a genuine failure is BLOCK. Reviewer cross-audits every tolerance in `audit.md` against `test-spec.md` and `sim-spec.md`.
