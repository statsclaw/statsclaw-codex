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
| Claude Code slash commands | Codex skills under `skills/<name>/SKILL.md`, invoked with `$<name>` or natural language (Codex does not expose `~/.codex/prompts/` as user slash commands) |
| `${CLAUDE_PLUGIN_ROOT}` | `${STATSCLAW_CODEX_ROOT}` |
| `${CLAUDE_PLUGIN_DATA}` | `${STATSCLAW_CODEX_DATA}` (default `~/.codex/data/statsclaw/`) |

Everything else — gates, preconditions, state transitions, must-not rules, the brain protocol, the workflow catalog, the 9 language profiles — is identical to upstream.

---

## Install

### Prerequisites

- **Codex CLI** (OpenAI) — [install guide](https://github.com/openai/codex)
- **Git** with either `gh`, a SSH key, `$GITHUB_TOKEN`, or a credential helper
- **Your target language toolchain** (R, Python, Julia, Stata, TypeScript, Go, Rust, C, C++)

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/statsclaw/statsclaw-codex/main/install-remote.sh | bash
```

Then:

```bash
codex                  # open a NEW terminal first so the env loads
/plugins               # inside Codex: browse the marketplace
install statsclaw      # install the plugin
```

That's it. From now on, every Codex session has StatsClaw available. Trigger any workflow with a `$skill-name` mention or natural language:

```
$patrol xuyiqing/fect
$simulate finite-sample properties of this estimator
$ship-it
$review
$contribute
$brain on
$loop 30m $patrol fect
```

Natural language also works — Codex matches each skill's `description`, so `"patrol open issues on xuyiqing/fect"` auto-triggers `$patrol`.

### What the one-liner does, end to end

1. Clones `statsclaw/statsclaw-codex` into `~/.codex/plugins/statsclaw` (or pulls if already there).
2. Runs `install.sh` which:
   - Writes `STATSCLAW_CODEX_ROOT` / `STATSCLAW_CODEX_DATA` / `PATH` into `~/.codex/env.sh`.
   - Imports the protocol into `~/.codex/AGENTS.md` (so every Codex session inherits it).
   - Merges `[profiles.statsclaw-*]` blocks into `~/.codex/config.toml`, preserving your existing settings.
   - Registers a user-scoped Codex marketplace at `~/.agents/plugins/marketplace.json` that points at this checkout as a local plugin source. `/plugins` inside Codex will list StatsClaw there.
   - Hooks `source ~/.codex/env.sh` into `~/.bashrc` and/or `~/.zshrc`, so new terminals auto-load the env.
   - Creates the runtime data dir `~/.codex/data/statsclaw/`.

The installer and its hook are **idempotent** — re-running never duplicates lines.

### Two-step install (if you don't like `curl | bash`)

```bash
git clone https://github.com/statsclaw/statsclaw-codex ~/.codex/plugins/statsclaw
bash ~/.codex/plugins/statsclaw/install.sh
```

### Skip the shell-rc hook

```bash
bash ~/.codex/plugins/statsclaw/install.sh --no-shell-hook
# or for the remote installer:
STATSCLAW_NO_SHELL_HOOK=1 curl -fsSL https://raw.githubusercontent.com/statsclaw/statsclaw-codex/main/install-remote.sh | bash
```

### User-facing skills (`$skill-name`)

| Skill | Purpose |
| --- | --- |
| `$patrol` | Scan + auto-fix open GitHub issues on a target repo (workflow 4) |
| `$simulate` | Monte Carlo simulation study for finite-sample properties (workflow 11/12) |
| `$ship-it` | Review + commit + push + open PR (workflow 7) |
| `$review` | Convergence check; issues a ship/no-ship verdict (workflow 8) |
| `$contribute` | Extract session knowledge and (with consent) PR it to `statsclaw/brain-seedbank` |
| `$brain` | Turn brain mode on/off or print status |
| `$loop` | Run any of the above on a recurring interval |

All other skills in `skills/` are internal protocol files — they are loaded by the leader but cannot be triggered by user input (their descriptions are prefixed `[Internal protocol — leader-only …]`).

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
