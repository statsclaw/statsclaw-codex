# StatsClaw-Codex Roadmap

> **Vision**: Input a paper, a conversation, or a set of formulas — get a production-ready statistical package. Available on OpenAI Codex CLI with full parity to the upstream [Claude Code version](https://github.com/statsclaw/statsclaw).

StatsClaw-Codex is the OpenAI Codex CLI port of StatsClaw. It tracks the same product roadmap as the upstream — the port exists to make the 9-agent adversarial-verification workflow available wherever the user prefers to run Codex CLI. This roadmap tracks where we are and where we're headed.

---

## Phase 0: Port Maturity (Current focus for this repo)

- [x] Full port of the 9 agent definitions (leader, planner, builder, tester, scriber, reviewer, simulator, distiller, shipper)
- [x] Full port of all 15 protocol skills (`statsclaw-protocol`, `brain-sync`, `contribute`, `credential-setup`, `handoff`, `isolation`, `issue-patrol`, `mailbox`, `privacy-scrub`, `profile-detection`, `progress-bar`, `simplified-workflow`, `simulation-study`, `workspace-sync`, `attribution`)
- [x] 9 language profiles shared verbatim with upstream
- [x] `scripts/dispatch.sh` wrapper — Codex equivalent of the `Agent` tool
- [x] `scripts/worktree.sh` — `isolation: worktree` implementation
- [x] `scripts/detect-credentials.sh` — credential gate
- [x] `scripts/loop.sh` — recurring-execution primitive
- [x] Slash commands in `prompts/` (`/contribute`, `/loop`, `/ship-it`, `/review`, `/patrol`, `/simulate`, `/brain`)
- [x] `install.sh` / `uninstall.sh` — register plugin with `~/.codex/`
- [x] `codex-config.example.toml` — per-agent Codex profiles
- [x] CI for structure validation, markdown lint, YAML lint
- [ ] Integration tests that actually invoke `codex exec` against a scratch target repo
- [ ] Documented migration path for existing StatsClaw-on-Claude users who want to try the Codex version side-by-side

## Phase 1: Foundation (Shared with upstream)

- [x] Multi-pipeline agent architecture (leader, planner, builder, tester, scriber, reviewer, shipper)
- [x] Pipeline isolation (code / test / simulation never see each other's specs)
- [x] 9 language profiles (R, Python, Julia, TypeScript, Stata, Go, Rust, C, C++)
- [x] Workspace repo for runtime state and audit trails
- [x] Issue patrol — scan and auto-fix GitHub issues
- [x] Simulation study workflows (Monte Carlo, DGP, coverage)
- [ ] Comprehensive test suite for the framework itself
- [x] CI/CD pipeline for StatsClaw-Codex repo
- [x] Brain knowledge-sharing system (distiller agent, brain-sync, privacy-scrub)
- [x] Companion repos: [`statsclaw/brain`](https://github.com/statsclaw/brain), [`statsclaw/brain-seedbank`](https://github.com/statsclaw/brain-seedbank) — shared across Claude Code and Codex versions

## Phase 2: Paper-to-Package Pipeline

- [ ] PDF/LaTeX paper ingestion — extract algorithms, theorems, estimators
- [ ] Formula-to-code translation with mathematical verification
- [ ] Auto-generate unit tests from paper's simulation section
- [ ] Auto-generate vignettes/tutorials from paper's examples
- [ ] Support for common paper formats (arXiv, NBER, journal PDFs)

## Phase 3: Interactive Specification

- [ ] Long-form conversation mode — refine specs through dialogue
- [ ] LaTeX formula input → structured spec generation
- [ ] Visual diagram support (DAGs, model diagrams)
- [ ] Interactive simulation design — choose DGP parameters conversationally
- [ ] Incremental refinement — update package from follow-up papers

## Phase 4: Multi-Language & Ecosystem

- [ ] Cross-language package generation (same estimator → R + Python + Stata)
- [ ] CRAN/PyPI/npm submission automation
- [ ] Dependency management across ecosystems
- [ ] pkgdown / Quarto documentation site generation
- [ ] Stata SSC submission support

## Phase 5: Community & Scale

- [ ] Plugin architecture — community-contributed profiles and skills
- [ ] Shared estimator registry — browse and build on existing implementations
- [ ] Brain knowledge expansion — grow the shared knowledge base across domains
- [ ] Brain search improvements — tag-based and semantic search for knowledge entries
- [ ] Brain analytics — track which knowledge entries are most useful
- [ ] Collaborative workflow — multiple contributors on one package
- [ ] Benchmark suite — auto-compare new estimator against existing methods
- [ ] Continuous integration for generated packages

## Phase 6: Intelligence

- [ ] Automatic literature review — find related estimators and compare
- [ ] Numerical stability analysis built into code generation
- [ ] Performance profiling and optimization suggestions
- [ ] Auto-detect edge cases from mathematical properties

---

## How to Influence This Roadmap

This roadmap is community-driven. You can shape it:

- **Feature requests**: [Open an issue](../../issues/new?template=feature-request.yml) with your idea
- **Paper-to-Package requests**: [Submit a paper](../../issues/new?template=paper-to-package.yml) you want turned into a package
- **Discussions**: Join the [Ideas discussion board](../../discussions/categories/ideas) to brainstorm
- **Direct contributions**: See [CONTRIBUTING.md](CONTRIBUTING.md) to get started

Every feature request and discussion thread feeds back into this roadmap. We review and prioritize monthly.
