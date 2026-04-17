---
name: simulate
description: Run a Monte Carlo simulation study to evaluate finite-sample properties (bias, RMSE, coverage, size, power) of a statistical estimator. Use this skill whenever the user asks to "run a simulation", "Monte Carlo", "simulate a DGP", "check coverage", "finite-sample properties", "calibration study", or invokes $simulate explicitly. Handles both Workflow 11 (new estimator + simulation evidence) and Workflow 12 (simulation-only on an existing estimator). Enforces three-way pipeline isolation — code, test, and simulation agents never see each other's specs.
metadata:
  short-description: Monte Carlo simulation study — workflow 11/12
---

# Skill: Simulate — Monte Carlo simulation study

You are the StatsClaw leader. The user has triggered `$simulate` (or described a simulation-shaped task in natural language).

The authoritative procedure lives in `skills/simulation-study/SKILL.md` — load that file and follow it exactly. This skill is the **entry point** that routes to the right workflow.

## Workflow selection

Determine the workflow from the user's intent:

- **Workflow 11 (Simulation + Code)** — the user is introducing a new estimator AND wants simulation evidence.
  - Dispatch order: `planner → [builder ∥ simulator] → tester → scriber → [distiller]? → reviewer → shipper?`
  - Builder and simulator dispatch in **parallel** (same message from leader).
  - Builder gets only `spec.md`; simulator gets only `sim-spec.md`.
  - After both complete and their worktrees merge back, dispatch tester with only `test-spec.md`. Tester validates unit tests AND runs the full simulation, comparing results against acceptance criteria.

- **Workflow 12 (Simulation Only)** — the estimator already exists, the user wants a Monte Carlo study on it.
  - Dispatch order: `planner → simulator → tester → scriber → [distiller]? → reviewer → shipper?`
  - No builder.

## Three-way pipeline isolation (absolute)

- Builder never sees `test-spec.md` or `sim-spec.md`.
- Tester never sees `spec.md` or `sim-spec.md`.
- Simulator never sees `spec.md` or `test-spec.md`.
- Planner bridges all three — only planner holds the full comprehension.

See `skills/isolation/SKILL.md` for the worktree mechanics.

## Tolerance integrity is absolute

Tester MUST NEVER relax tolerances or acceptance criteria to make a failing simulation pass. The only valid response to a genuine failure is BLOCK. Reviewer cross-audits every tolerance in `audit.md` against `test-spec.md` and `sim-spec.md`.

## If the user's request is ambiguous

If it's unclear whether the user wants Workflow 11 or 12 (e.g., "simulate this estimator" when the estimator may or may not already exist), ask a numbered-options question before dispatching planner.
