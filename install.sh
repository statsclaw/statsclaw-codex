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
#
# Idempotent — safe to run multiple times.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
DATA="${STATSCLAW_CODEX_DATA:-$CODEX_HOME/data/statsclaw}"

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
  echo "[1/5] wrote env to $ENV_FILE"
else
  # update in place
  sed -i.bak "s|^export STATSCLAW_CODEX_ROOT=.*|export STATSCLAW_CODEX_ROOT=\"$ROOT\"|" "$ENV_FILE"
  sed -i.bak "s|^export STATSCLAW_CODEX_DATA=.*|export STATSCLAW_CODEX_DATA=\"$DATA\"|" "$ENV_FILE"
  rm -f "$ENV_FILE.bak"
  echo "[1/5] updated env in $ENV_FILE"
fi

# 2. AGENTS.md -----------------------------------------------------------
GLOBAL_AGENTS="$CODEX_HOME/AGENTS.md"
IMPORT_LINE="@$ROOT/AGENTS.md"
if [[ ! -f "$GLOBAL_AGENTS" ]]; then
  cat > "$GLOBAL_AGENTS" <<EOF
# Codex — Global AGENTS.md

$IMPORT_LINE
EOF
  echo "[2/5] created $GLOBAL_AGENTS with StatsClaw-Codex import"
elif ! grep -qF "$IMPORT_LINE" "$GLOBAL_AGENTS"; then
  printf '\n%s\n' "$IMPORT_LINE" >> "$GLOBAL_AGENTS"
  echo "[2/5] appended StatsClaw-Codex import to $GLOBAL_AGENTS"
else
  echo "[2/5] StatsClaw-Codex import already present in $GLOBAL_AGENTS"
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
echo "[3/5] symlinked $(ls "$ROOT"/prompts/*.md | wc -l | tr -d ' ') slash commands into $CODEX_HOME/prompts/"

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
  echo "[4/5] appended StatsClaw-Codex profiles to $CONFIG"
else
  echo "[4/5] StatsClaw-Codex profiles already present in $CONFIG — leaving untouched"
fi

# 5. runtime dir ---------------------------------------------------------
echo "[5/5] runtime data dir ready at $DATA"
echo
echo "Done. Open a new shell, or run:   source $ENV_FILE"
echo
echo "Try it:"
echo "  codex               # start a session; AGENTS.md is auto-loaded"
echo "  /contribute         # invoke a slash command"
echo "  /patrol fect        # run issue patrol on xuyiqing/fect"
