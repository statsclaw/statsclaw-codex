---
name: review
description: Cross-check pipelines and issue a ship/no-ship verdict (workflow 8 — reviewer only).
---

# /review — Convergence check without shipping

You are the StatsClaw-Codex leader. The user has invoked `/review`.

Run **Workflow 8 (Review Only)** from the protocol catalog:

```
leader → reviewer
```

Steps:

1. Locate the most recent run directory under `${STATSCLAW_CODEX_DATA}/workspace/<repo>/runs/`, or use the run the user specifies.
2. Dispatch reviewer via `scripts/dispatch.sh reviewer <run-dir>`.
3. Reviewer reads ALL artifacts (request.md, impact.md, comprehension.md, spec.md, test-spec.md, sim-spec.md if present, implementation.md, simulation.md if present, audit.md, ARCHITECTURE.md, log-entry.md, docs.md, brain-contributions.md if present) and writes `review.md`.
4. Report the verdict (PASS / PASS WITH NOTE / STOP) and the routing (which teammate reviewer identified as responsible for any issues) back to the user.

Do NOT dispatch shipper. This workflow is review-only — the user decides whether to invoke `/ship-it` afterward.
