#!/usr/bin/env bash
#
# install.sh — register StatsClaw-Codex with the user's Codex CLI
#
# Behaviour:
#   1. Writes STATSCLAW_CODEX_ROOT + STATSCLAW_CODEX_DATA into ~/.codex/env.sh
#   2. Adds `@<root>/AGENTS.md` import to ~/.codex/AGENTS.md (if not present)
#   3. Symlinks prompts/*.md into ~/.codex/prompts/
#   4. Merges [profiles.statsclaw-*] blocks from codex-config.example.toml
#      into ~/.codex/config.toml (only if they don't already exist)
#   5. Creates ${STATSCLAW_CODEX_DATA}/ runtime dir
#   6. Hooks `source ~/.codex/env.sh` into the user's shell rc (~/.bashrc,
#      ~/.zshrc) so new shells pick up the env automatically. Pass
#      `--no-shell-hook` to skip this step.
#
# Idempotent — safe to run multiple times.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
DATA="${STATSCLAW_CODEX_DATA:-$CODEX_HOME/data/statsclaw}"
SHELL_HOOK=1

for arg in "$@"; do
  case "$arg" in
    --no-shell-hook) SHELL_HOOK=0 ;;
    -h|--help)
      echo "usage: $0 [--no-shell-hook]"
      exit 0
      ;;
  esac
done

echo "StatsClaw-Codex installer"
echo "  framework root: $ROOT"
echo "  codex home:     $CODEX_HOME"
echo "  runtime data:   $DATA"
echo

mkdir -p "$CODEX_HOME/prompts" "$DATA/workspace" "$DATA/worktrees"

# 1. env.sh --------------------------------------------------------------
ENV_FILE="$CODEX_HOME/env.sh"
touch "$ENV_FILE"
if ! grep -q "STATSCLAW_CODEX_ROOT=" "$ENV_FILE"; then
  {
    echo ""
    echo "# StatsClaw-Codex"
    echo "export STATSCLAW_CODEX_ROOT=\"$ROOT\""
    echo "export STATSCLAW_CODEX_DATA=\"$DATA\""
    echo "export PATH=\"\$STATSCLAW_CODEX_ROOT/scripts:\$PATH\""
  } >> "$ENV_FILE"
  echo "[1/6] wrote env to $ENV_FILE"
else
  # update in place
  sed -i.bak "s|^export STATSCLAW_CODEX_ROOT=.*|export STATSCLAW_CODEX_ROOT=\"$ROOT\"|" "$ENV_FILE"
  sed -i.bak "s|^export STATSCLAW_CODEX_DATA=.*|export STATSCLAW_CODEX_DATA=\"$DATA\"|" "$ENV_FILE"
  rm -f "$ENV_FILE.bak"
  echo "[1/6] updated env in $ENV_FILE"
fi

# 2. AGENTS.md -----------------------------------------------------------
GLOBAL_AGENTS="$CODEX_HOME/AGENTS.md"
IMPORT_LINE="@$ROOT/AGENTS.md"
if [[ ! -f "$GLOBAL_AGENTS" ]]; then
  cat > "$GLOBAL_AGENTS" <<EOF
# Codex — Global AGENTS.md

$IMPORT_LINE
EOF
  echo "[2/6] created $GLOBAL_AGENTS with StatsClaw-Codex import"
elif ! grep -qF "$IMPORT_LINE" "$GLOBAL_AGENTS"; then
  printf '\n%s\n' "$IMPORT_LINE" >> "$GLOBAL_AGENTS"
  echo "[2/6] appended StatsClaw-Codex import to $GLOBAL_AGENTS"
else
  echo "[2/6] StatsClaw-Codex import already present in $GLOBAL_AGENTS"
fi

# 3. prompts -------------------------------------------------------------
for p in "$ROOT"/prompts/*.md; do
  name="$(basename "$p")"
  target="$CODEX_HOME/prompts/$name"
  if [[ -L "$target" || -f "$target" ]]; then
    if [[ "$(readlink -f "$target" 2>/dev/null || echo)" == "$p" ]]; then
      continue
    fi
    echo "  - skipping $name (target already exists and differs — rename it first)"
    continue
  fi
  ln -s "$p" "$target"
done
echo "[3/6] symlinked $(ls "$ROOT"/prompts/*.md | wc -l | tr -d ' ') slash commands into $CODEX_HOME/prompts/"

# 4. config.toml profiles ------------------------------------------------
CONFIG="$CODEX_HOME/config.toml"
EXAMPLE="$ROOT/codex-config.example.toml"
touch "$CONFIG"
if ! grep -q '\[profiles\.statsclaw-leader\]' "$CONFIG"; then
  {
    echo ""
    echo "# --- StatsClaw-Codex profiles (added by install.sh) ---"
    sed -n '/^# ==== StatsClaw-Codex profiles/,$p' "$EXAMPLE"
  } >> "$CONFIG"
  echo "[4/6] appended StatsClaw-Codex profiles to $CONFIG"
else
  echo "[4/6] StatsClaw-Codex profiles already present in $CONFIG — leaving untouched"
fi

# 5. runtime dir ---------------------------------------------------------
echo "[5/6] runtime data dir ready at $DATA"

# 6. shell rc hook -------------------------------------------------------
HOOK_LINE="[ -f \"$ENV_FILE\" ] && . \"$ENV_FILE\"  # StatsClaw-Codex"
HOOK_MARK="# StatsClaw-Codex"
hook_into() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  if grep -qF "$HOOK_MARK" "$rc"; then
    echo "  - hook already present in $rc"
    return 0
  fi
  {
    echo ""
    echo "$HOOK_LINE"
  } >> "$rc"
  echo "  - appended hook to $rc"
}

if [[ $SHELL_HOOK -eq 1 ]]; then
  # Detect shell rc files. Handle bash + zsh; if neither exists, create ~/.profile.
  hooked=0
  if [[ -f "$HOME/.bashrc" ]]; then
    hook_into "$HOME/.bashrc" && hooked=1
  fi
  if [[ -f "$HOME/.zshrc" ]]; then
    hook_into "$HOME/.zshrc" && hooked=1
  fi
  if [[ $hooked -eq 0 ]]; then
    # Fallback — create ~/.profile so login shells still pick it up.
    touch "$HOME/.profile"
    hook_into "$HOME/.profile"
  fi
  echo "[6/6] shell-rc hook installed — new shells auto-load the env"
  # Also source it into the current shell if this script was sourced.
  # When executed (not sourced), we can't mutate the caller; print the command instead.
  # shellcheck disable=SC2296
  if (return 0 2>/dev/null); then
    # shellcheck disable=SC1090
    . "$ENV_FILE"
  fi
else
  echo "[6/6] skipping shell-rc hook (--no-shell-hook)"
fi

echo
echo "Done."
if [[ $SHELL_HOOK -eq 1 ]]; then
  echo "Open a NEW shell (or \`source $ENV_FILE\` in this one) and try:"
else
  echo "Run \`source $ENV_FILE\` and try:"
fi
echo "  codex               # start a session; AGENTS.md is auto-loaded"
echo "  /contribute         # invoke a slash command"
echo "  /patrol fect        # run issue patrol on xuyiqing/fect"
