# StatsClaw-Codex

**The OpenAI Codex CLI port of [StatsClaw](https://github.com/statsclaw/statsclaw).**

StatsClaw-Codex implements the full StatsClaw agent-teams framework — the 9 specialist agents, the three-pipeline (code / test / simulation) adversarial-verification architecture, issue patrol, simulation studies, workspace sync, and the shared-brain knowledge system — on top of OpenAI Codex CLI primitives (`AGENTS.md`, `~/.codex/config.toml`, `~/.codex/prompts/`, `codex exec`).

> **Scope.** This repository is a port, not a fork of the upstream. The upstream protocol, the brain repos (`statsclaw/brain`, `statsclaw/brain-seedbank`), and the example packages (`example-fect`, `example-probit`, etc.) are **shared** across the Claude Code and Codex versions — a contribution from a Codex user benefits Claude Code users and vice-versa.

---

## What is StatsClaw?

StatsClaw orchestrates a team of **9 specialized AI agents**, each operating under strict information isolation:

| Agent | Role |
|:------|:-----|
| **Leader** | Orchestrates the workflow, dispatches agents, enforces isolation |
| **Planner** | Reads your paper/formulas, executes deep comprehension protocol, produces specifications |
| **Builder** | Writes source code from `spec.md` (never sees the test spec) |
| **Tester** | Validates independently from `test-spec.md` (never sees the code spec) |
| **Simulator** | Runs Monte Carlo studies from `sim-spec.md` (never sees either spec) |
| **Scriber** | Documents architecture, generates tutorials, maintains audit trail |
| **Distiller** | Extracts reusable knowledge for the shared brain (brain mode only) |
| **Reviewer** | Cross-checks all pipelines, audits tolerance integrity, issues ship/no-ship verdict |
| **Shipper** | Commits, pushes, opens PRs, handles package distribution |

Code, test, and simulation pipelines are fully isolated — they never see each other's specs. If all pipelines converge independently, confidence in correctness is high. This is **adversarial verification by design**.

See the [upstream README](https://github.com/statsclaw/statsclaw#readme) for the full protocol description — the design is identical.

---

## What's different on Codex?

| Upstream (Claude Code) | This port (Codex CLI) |
| --- | --- |
| `CLAUDE.md` | `AGENTS.md` |
| `Agent` tool for dispatch | `scripts/dispatch.sh <role>` wrapping `codex exec --profile <role>` |
| `isolation: "worktree"` frontmatter | `scripts/dispatch.sh --worktree` (automatic `git worktree add` + merge-back) |
| `AskUserQuestion` tool | Leader prints a numbered-options markdown question and yields the turn |
| `Skill` tool | File-reference load of `skills/<name>/SKILL.md` |
| `~/.claude/settings.json` | `~/.codex/config.toml` `[profiles.statsclaw-*]` |
| Claude Code slash commands | `~/.codex/prompts/*.md` — invoked with `/<name>` |
| `${CLAUDE_PLUGIN_ROOT}` | `${STATSCLAW_CODEX_ROOT}` |
| `${CLAUDE_PLUGIN_DATA}` | `${STATSCLAW_CODEX_DATA}` (default `~/.codex/data/statsclaw/`) |

Everything else — gates, preconditions, state transitions, must-not rules, the brain protocol, the workflow catalog, the 9 language profiles — is identical to upstream.

---

## Install

### Prerequisites

- **Codex CLI** (OpenAI) — [install guide](https://github.com/openai/codex)
- **Git** with either `gh`, a SSH key, `$GITHUB_TOKEN`, or a credential helper
- **Your target language toolchain** (R, Python, Julia, Stata, TypeScript, Go, Rust, C, C++)

### Global install (recommended)

```bash
git clone https://github.com/statsclaw/statsclaw-codex ~/.codex/plugins/statsclaw
bash ~/.codex/plugins/statsclaw/install.sh
```

`install.sh` is idempotent. It:

- Appends `@<root>/AGENTS.md` into `~/.codex/AGENTS.md` so every Codex session inherits the protocol.
- Symlinks `prompts/*.md` into `~/.codex/prompts/` so `/contribute`, `/loop`, `/ship-it`, `/review`, `/patrol`, `/simulate`, `/brain` are available as slash commands.
- Merges `[profiles.statsclaw-*]` blocks into `~/.codex/config.toml` (existing user settings preserved).
- Exports `STATSCLAW_CODEX_ROOT` and `STATSCLAW_CODEX_DATA` in `~/.codex/env.sh`.
- Prepends `scripts/` to `$PATH` so `dispatch.sh`, `worktree.sh`, `detect-credentials.sh`, and `loop.sh` are on your path.

After installation, open a new shell (or `source ~/.codex/env.sh`) and you're set:

```bash
codex                    # start a session — AGENTS.md is auto-loaded
/patrol fect on cfe      # run issue patrol
/simulate finite-sample properties of the new estimator
/ship-it                 # push reviewed changes
/contribute              # submit session lessons to the shared brain
```

### Per-project install

Drop this repo into your project and add a minimal `AGENTS.md` at the project root:

```markdown
@./statsclaw-codex/AGENTS.md
```

This opts the project into StatsClaw workflow without touching global Codex config.

### Uninstall

```bash
bash ~/.codex/plugins/statsclaw/uninstall.sh          # remove integration, keep data
bash ~/.codex/plugins/statsclaw/uninstall.sh --purge  # also delete runtime data
```

---

## Quick start

Tell Codex what you want, in any language:

```
work on https://github.com/your-org/your-package — resolve the open issues
```

Leader parses the prompt, detects the language, selects a workflow, verifies credentials, and starts working. It only pauses when it genuinely needs your input (HOLD signal).

### Common prompts

```
# Single issue
fix issue #42 in my-package

# Bulk issue patrol on a branch
patrol fect issues on cfe

# Monitor a repo on an interval
/loop 30m patrol fect issues

# Simulation study (new estimator)
build the estimator from Xu (2025) and simulate its finite-sample properties

# Simulation study (existing estimator)
run a Monte Carlo study of coverage and power for my-package::foo

# Ship reviewed work
/ship-it

# Review without shipping
/review

# Contribute reusable knowledge
/contribute

# Toggle brain mode
/brain on
/brain status
/brain off
```

---

## Architecture

```
                      planner (bridge)
                     /    |          \
          spec.md   / test-spec.md    \  sim-spec.md
                   /      |            \
            builder ─ ─(parallel)─ ─ simulator
       (code pipeline)    |    (simulation pipeline)
                   \      |            /
      implementation.md   |   simulation.md
                    \     |          /
                     \    v         /
                       tester           <-- sequential, after merge-back
                    (test pipeline)
                         |
                      audit.md
                         |
                    scriber (recording)
                         |
                    distiller (brain mode only)
                         |
                    reviewer (convergence)
                         |
                       shipper
```

See `AGENTS.md` and `skills/statsclaw-protocol/SKILL.md` for the full catalog of workflows (1–13), hard gates, state model, signal handling, and dispatch rules.

---

## Runtime layout

Nothing is created in your project directory in global-install mode. All runtime state lives under `${STATSCLAW_CODEX_DATA}/` (default `~/.codex/data/statsclaw/`):

```text
~/.codex/data/statsclaw/
├── <target-repo>/              # cloned target repo (if not already on disk)
├── brain/                      # statsclaw/brain (brain mode only)
├── brain-seedbank/             # statsclaw/brain-seedbank (brain mode only)
├── worktrees/                  # transient git worktrees for writer teammates
└── workspace/                  # YOUR workspace repo (pushed to GitHub)
    └── <repo-name>/
        ├── context.md          # per-repo context + BrainMode setting
        ├── CHANGELOG.md        # timeline of all runs (pushed)
        ├── HANDOFF.md          # active handoff (pushed)
        ├── ref/                # reference docs for future work (pushed)
        └── runs/
            └── <request-id>/   # all per-run artifacts (request, spec, audit, review, ...)
```

---

## Shared brain

StatsClaw-Codex reads and contributes to the **same** shared brain as upstream:

| Repo | Purpose |
|:-----|:--------|
| [`statsclaw/brain`](https://github.com/statsclaw/brain) | Curated knowledge — agents read from here |
| [`statsclaw/brain-seedbank`](https://github.com/statsclaw/brain-seedbank) | Contribution staging — users submit PRs here |

Brain mode is **opt-in**. At session start, if `BrainMode` is unset, leader asks. If `"connected"`, agents read relevant entries at dispatch time and may propose new entries (via distiller) at workflow end. Every contribution is privacy-scrubbed and requires explicit per-entry user consent before upload.

Codex contributions and Claude Code contributions populate the same knowledge base — the community is unified across runtimes.

---

## Supported languages

| R | Python | Julia | Stata | TypeScript | Go | Rust | C | C++ |
|:-:|:------:|:-----:|:-----:|:----------:|:--:|:----:|:-:|:---:|

Profiles live in `profiles/` and define validation commands, idioms, and style rules per language.

---

## Relationship to upstream

This port tracks upstream [statsclaw/statsclaw](https://github.com/statsclaw/statsclaw) closely. When upstream updates:

- **Protocol changes** (new workflows, new gates, new agents) → ported here as fast as we can; open an issue if something seems out of sync.
- **Agent behaviour fixes** → usually a verbatim port of the text edits in upstream `agents/*.md`.
- **New profiles / templates** → copied verbatim (they are platform-agnostic).
- **Claude-specific tool changes** (new `Agent` tool parameters, new `Skill` semantics) → mapped to their Codex equivalents in `scripts/dispatch.sh` or the skill adapters.

Contributions that touch the protocol should ideally land upstream first.

---

## Citation

If you use StatsClaw (any version) in your research or software development, please cite the upstream paper:

> Qin, Tianzhu and Yiqing Xu. 2026. "[StatsClaw: An AI-Collaborative Workflow for Statistical Software Development](https://bit.ly/statsclaw)."

```bibtex
@misc{qinxu2026statsclaw,
  title={StatsClaw: An AI-Collaborative Workflow for Statistical Software Development},
  author={Qin, Tianzhu and Xu, Yiqing},
  year={2026},
  howpublished={Mimeo, Stanford University},
  url={https://bit.ly/statsclaw}
}
```

---

## License

MIT. See [`LICENSE`](LICENSE).

---

## Links

- Upstream: https://github.com/statsclaw/statsclaw
- Brain: https://github.com/statsclaw/brain
- Brain seedbank: https://github.com/statsclaw/brain-seedbank
- OpenAI Codex CLI: https://github.com/openai/codex
- AGENTS.md spec: https://agents.md
