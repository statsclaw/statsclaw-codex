# StatsClaw-Codex — Agent Teams Framework for OpenAI Codex CLI

**StatsClaw-Codex** is the OpenAI Codex CLI port of [StatsClaw](https://github.com/statsclaw/statsclaw). It implements every capability of the upstream Claude Code plugin — the 9-agent workflow, the three-pipeline (code / test / simulation) isolation model, the brain knowledge system, issue patrol, simulation studies, workspace sync — on top of Codex CLI conventions (`AGENTS.md`, `~/.codex/config.toml`, `~/.codex/prompts/`, `codex exec` sub-invocation).

> Codex CLI reads this file automatically on session start. All protocol skills, agent definitions, profiles, and templates referenced below are loaded on demand.

@skills/statsclaw-protocol/SKILL.md

---

## Codex-Specific Execution Model

StatsClaw on Claude Code relies on the `Agent` tool for sub-agent dispatch, `AskUserQuestion` for pauses, and `Skill` for protocol loading. Codex CLI exposes a different surface, so the equivalent primitives are:

| StatsClaw-on-Claude | StatsClaw-on-Codex |
| --- | --- |
| `Agent` tool (dispatch teammate) | `scripts/dispatch.sh <role> <run_dir> [--worktree]` (wraps `codex exec --profile <role>`) |
| `isolation: "worktree"` frontmatter | `scripts/dispatch.sh --worktree` creates a `git worktree` and merges back after the child session commits |
| `AskUserQuestion` | Leader prints a numbered-options question in markdown and pauses the session — the user replies in the next turn |
| `Skill` tool (invoke skill) | Reference the skill's SKILL.md path in the prompt; the model loads it via file read |
| `ExitPlanMode` | Not required — Codex does not have plan mode; leader prints the plan and proceeds on user approval |
| Plugin-mode `${CLAUDE_PLUGIN_ROOT}` | `${STATSCLAW_CODEX_ROOT}` (set by `install.sh`) |
| Plugin-mode `${CLAUDE_PLUGIN_DATA}` | `${STATSCLAW_CODEX_DATA}` (defaults to `~/.codex/data/statsclaw/`) |
| `~/.claude/settings.json` `agent: leader` | `~/.codex/config.toml` `[profiles.statsclaw-leader]` |
| Claude Code slash commands | `~/.codex/prompts/<name>.md` — invoked with `/<name>` |

**Dispatch wrapper** (`scripts/dispatch.sh`) is the single primitive by which the leader spawns any specialist teammate. It:

1. Reads the teammate's frontmatter (`model`, `isolation`, `disallowedTools`) from `agents/<role>.md`.
2. If `isolation: worktree`, creates a git worktree at `${STATSCLAW_CODEX_DATA}/worktrees/<role>-<request-id>/` and `cd`s into it.
3. Invokes `codex exec --profile <role>-profile --full-auto --cd <path> "<prompt>"` with the agent file as the effective `AGENTS.md`.
4. On success, if the teammate was in a worktree, fast-forwards the worktree commit(s) back onto the target branch and removes the worktree.
5. Returns the teammate's final artifact path(s) to the leader.

Leader uses this wrapper exactly where the upstream Claude Code protocol says "dispatch via `Agent` tool". Every gate, every precondition, every must-not-rule from the upstream protocol applies unchanged.

---

## Installation

StatsClaw-Codex is distributed as a standalone Codex project plugin — no marketplace is required. Two install modes are supported:

### Global install (recommended)

```bash
git clone https://github.com/statsclaw/statsclaw-codex ~/.codex/plugins/statsclaw
bash ~/.codex/plugins/statsclaw/install.sh
```

`install.sh` performs the following:

- Appends a `@` import of this `AGENTS.md` into `~/.codex/AGENTS.md` so every Codex session inherits the protocol.
- Symlinks `prompts/*.md` into `~/.codex/prompts/` so `/contribute`, `/loop`, `/ship-it`, `/review`, `/patrol`, `/simulate`, `/brain` become available as slash commands.
- Writes `~/.codex/config.toml` entries under `[profiles.statsclaw-*]` for each agent (one profile per teammate), unless entries already exist.
- Exports `STATSCLAW_CODEX_ROOT` and `STATSCLAW_CODEX_DATA` in `~/.codex/env.sh`.
- Creates `${STATSCLAW_CODEX_DATA}/` (default `~/.codex/data/statsclaw/`) for workspace/brain clones.

### Per-project install

Drop this directory into a project and add a minimal `AGENTS.md` in the project root:

```markdown
@./statsclaw-codex/AGENTS.md
```

This opts the project into StatsClaw workflow without touching global Codex configuration.

---

## Entry Point

When a Codex session starts with this `AGENTS.md` loaded, the active agent is **leader**. The leader's full contract is in `agents/leader.md`; the orchestration protocol, hard gates, state model, signal handling, workflow catalog, and dispatch rules live in `skills/statsclaw-protocol/SKILL.md` (imported above).

Read `agents/leader.md` before doing anything. Then follow the **Mandatory Execution Protocol** in the protocol skill — it applies verbatim with the Codex adaptations listed above.

---

## Workflow Catalog (Codex Edition)

Identical to upstream StatsClaw. See `skills/statsclaw-protocol/SKILL.md` for the full catalog.

| # | Name | Trigger | Agent Sequence |
| --- | --- | --- | --- |
| 1 | Code Change | Code modification | `leader → planner → builder → tester → scriber → [distiller]? → reviewer` |
| 2 | Code + Ship | Code modification + push | `leader → planner → builder → tester → scriber → [distiller]? → reviewer → shipper` |
| 3 | Docs Only | Documentation-only changes | `leader → planner → scriber → reviewer` |
| 4 | Issue Patrol | Scan + fix multiple issues | `leader → /patrol → per issue: planner → builder → tester → scriber → [distiller]? → reviewer → shipper` |
| 5 | Single Issue | Fix one named issue | `leader → planner → builder → tester → scriber → [distiller]? → reviewer → shipper` |
| 6 | Validation | Run tests only | `leader → tester` |
| 7 | Ship Only | Push reviewed changes | `leader → reviewer → shipper` |
| 8 | Review Only | Assess without shipping | `leader → reviewer` |
| 9 | Scheduled Loop | Recurring execution | `leader → /loop → inner workflow` |
| 10 | Simplified | Small routine change (user confirms) | `leader → builder → tester → shipper?` |
| 11 | Simulation Study | New estimator + Monte Carlo evaluation | `leader → planner → [builder ∥ simulator] → tester → scriber → [distiller]? → reviewer → shipper?` |
| 12 | Simulation Only | Monte Carlo study on existing estimator | `leader → planner → simulator → tester → scriber → [distiller]? → reviewer → shipper?` |
| 13 | Contribute | User-invoked knowledge contribution (`/contribute`) | `leader → distiller → ASK USER → shipper (brain upload only)` |

---

## Simple Prompt Interface

Users should never need to learn framework terminology. Leader parses natural language (any language) and routes to the correct workflow automatically.

| User types | What happens |
| --- | --- |
| `patrol fect issues on cfe` | Scans open issues in xuyiqing/fect, fixes on `cfe` branch, pushes PRs, replies to issues |
| `fix fect issue #42` | Runs full workflow to fix issue #42, pushes fix, comments on the issue |
| `monitor fect issues every 30min` | Recurring patrol with 30-minute interval |
| `simulate the finite-sample properties` | Runs Monte Carlo simulation study (workflow 11 or 12) |
| `enable brain` | Enables Brain mode — agents read shared knowledge, noteworthy discoveries offered for contribution |
| `ship it` | Pushes current changes and creates PR |
| `/contribute` | Summarizes session lessons, extracts reusable knowledge, submits to the shared brain (with user consent) |

Routing is semantic — see `agents/leader.md` → Simple Prompt Routing for the full intent-detection table.

---

## Brain System

StatsClaw-Codex uses the same upstream brain: [`statsclaw/brain`](https://github.com/statsclaw/brain) (curated knowledge) and [`statsclaw/brain-seedbank`](https://github.com/statsclaw/brain-seedbank) (contribution staging). The protocol is platform-agnostic — contributions from Codex users and Claude Code users populate the same knowledge base.

See `skills/brain-sync/SKILL.md` for the full contract and `skills/contribute/SKILL.md` for the user-invoked `/contribute` flow.

---

## Runtime Layout

Identical to upstream. All runtime state lives inside the workspace repo, organized per target repository, under `${STATSCLAW_CODEX_DATA}/workspace/<repo-name>/`. Nothing is created in the user's project directory in plugin mode.

```text
${STATSCLAW_CODEX_DATA}/
├── <target-repo>/                    # target repo checkout (clone mode only)
├── brain/                            # statsclaw/brain clone (brain mode only)
├── brain-seedbank/                   # statsclaw/brain-seedbank clone (brain mode only)
├── worktrees/                        # transient worktrees for writer teammates
└── workspace/                        # workspace repo (GitHub)
    └── <repo-name>/
        ├── context.md
        ├── CHANGELOG.md
        ├── HANDOFF.md
        ├── ref/
        ├── runs/
        │   └── <request-id>/
        │       ├── credentials.md
        │       ├── request.md
        │       ├── status.md
        │       ├── impact.md
        │       ├── comprehension.md
        │       ├── spec.md
        │       ├── test-spec.md
        │       ├── sim-spec.md
        │       ├── implementation.md
        │       ├── simulation.md
        │       ├── audit.md
        │       ├── ARCHITECTURE.md
        │       ├── log-entry.md
        │       ├── docs.md
        │       ├── brain-contributions.md
        │       ├── review.md
        │       ├── shipper.md
        │       ├── mailbox.md
        │       └── locks/
        ├── logs/
        └── tmp/
```

---

## Principles

All principles from upstream StatsClaw apply verbatim:

- **Credentials first, work second.**
- **Team Leader dispatches, never does.**
- **Multi-pipeline, fully isolated.**
- **Planner first, always.**
- **Adversarial verification by design.**
- **Hard gates, not soft advice.**
- **Worktree isolation for writers.**
- **Ship actions are explicit.**
- **Surgical scope.**
- **Clean target repos.**
- **One runtime, one location.**
- **Writers parallel, tester after.**
- **Tolerance integrity is absolute.**
- **Collective knowledge, individual consent.**

---

## References

- Upstream: https://github.com/statsclaw/statsclaw
- Brain: https://github.com/statsclaw/brain
- Brain Seedbank: https://github.com/statsclaw/brain-seedbank
- OpenAI Codex CLI: https://github.com/openai/codex
- Codex `AGENTS.md` spec: https://agents.md
