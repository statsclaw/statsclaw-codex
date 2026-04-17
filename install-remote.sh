#!/usr/bin/env bash
#
# install-remote.sh — one-liner installer for StatsClaw-Codex.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/statsclaw/statsclaw-codex/main/install-remote.sh | bash
#   wget -qO- https://raw.githubusercontent.com/statsclaw/statsclaw-codex/main/install-remote.sh | bash
#
# What it does:
#   1. Clones (or pulls) statsclaw/statsclaw-codex into ~/.codex/plugins/statsclaw
#   2. Runs install.sh which:
#        - writes STATSCLAW_CODEX_* env + PATH into ~/.codex/env.sh
#        - imports AGENTS.md into ~/.codex/AGENTS.md
#        - merges [profiles.statsclaw-*] into ~/.codex/config.toml
#        - creates runtime data dir
#        - registers the plugin in ~/.agents/plugins/marketplace.json
#        - hooks `source ~/.codex/env.sh` into ~/.bashrc / ~/.zshrc
#
# After this, run `codex`, then `/plugins` inside Codex to install the plugin,
# then trigger any skill with `$patrol`, `$simulate`, `$ship-it`, etc.
#
# Environment knobs:
#   STATSCLAW_CODEX_REPO    Git remote (default: https://github.com/statsclaw/statsclaw-codex.git)
#   STATSCLAW_CODEX_BRANCH  Branch to check out (default: main)
#   STATSCLAW_CODEX_DIR     Clone location (default: ~/.codex/plugins/statsclaw)
#   STATSCLAW_NO_SHELL_HOOK Set to 1 to skip the shell-rc hook

set -euo pipefail

REPO="${STATSCLAW_CODEX_REPO:-https://github.com/statsclaw/statsclaw-codex.git}"
BRANCH="${STATSCLAW_CODEX_BRANCH:-main}"
DIR="${STATSCLAW_CODEX_DIR:-$HOME/.codex/plugins/statsclaw}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git not found — install git first."
command -v bash >/dev/null 2>&1 || die "bash not found."

say "Installing StatsClaw-Codex"
say "  repo:    $REPO"
say "  branch:  $BRANCH"
say "  target:  $DIR"
echo

mkdir -p "$(dirname "$DIR")"

if [[ -d "$DIR/.git" ]]; then
  say "updating existing checkout"
  git -C "$DIR" fetch --quiet --depth=1 origin "$BRANCH"
  git -C "$DIR" checkout --quiet "$BRANCH"
  git -C "$DIR" reset --hard --quiet "origin/$BRANCH"
elif [[ -e "$DIR" ]]; then
  die "$DIR exists but is not a git checkout. Move or remove it and retry."
else
  say "cloning"
  git clone --quiet --depth=1 --branch "$BRANCH" "$REPO" "$DIR"
fi

say "running install.sh"
# Safe under bash 3.2 + set -u — no arrays, pass args as plain positional params.
if [[ "${STATSCLAW_NO_SHELL_HOOK:-0}" == "1" ]]; then
  bash "$DIR/install.sh" --no-shell-hook
else
  bash "$DIR/install.sh"
fi

cat <<EOF

==> StatsClaw-Codex is ready.

Next steps:
  1. Open a NEW terminal (so the env + shell-rc hook take effect).
  2. Run:   codex
  3. Inside Codex:   /plugins           # browse the marketplace
                     install statsclaw  # install the plugin
  4. Trigger any skill:
       \$patrol <owner/repo>   |   \$simulate <idea>   |   \$ship-it
       \$review                |   \$contribute       |   \$brain on|off|status
       \$loop <interval> <cmd>

Natural language also works — Codex matches the skill description.
E.g. "patrol open issues on xuyiqing/fect" auto-triggers \$patrol.
EOF
