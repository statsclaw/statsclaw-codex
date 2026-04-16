#!/usr/bin/env bash
#
# uninstall.sh — remove StatsClaw-Codex integration from the user's Codex CLI
#
# Does NOT delete the runtime data dir (${STATSCLAW_CODEX_DATA}) by default
# because it contains the user's workspace clones and run logs. Pass --purge
# to also remove that.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
DATA="${STATSCLAW_CODEX_DATA:-$CODEX_HOME/data/statsclaw}"
PURGE=0

for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=1 ;;
    -h|--help) echo "usage: $0 [--purge]"; exit 0 ;;
  esac
done

echo "StatsClaw-Codex uninstaller"
echo

# 1. env.sh
ENV_FILE="$CODEX_HOME/env.sh"
if [[ -f "$ENV_FILE" ]]; then
  sed -i.bak '/# StatsClaw-Codex/,/^$/d; /STATSCLAW_CODEX_/d' "$ENV_FILE"
  rm -f "$ENV_FILE.bak"
  echo "[1/4] removed env vars from $ENV_FILE"
fi

# 2. AGENTS.md import
GLOBAL_AGENTS="$CODEX_HOME/AGENTS.md"
if [[ -f "$GLOBAL_AGENTS" ]]; then
  sed -i.bak "\|@$ROOT/AGENTS.md|d" "$GLOBAL_AGENTS"
  rm -f "$GLOBAL_AGENTS.bak"
  echo "[2/4] removed AGENTS.md import from $GLOBAL_AGENTS"
fi

# 3. prompts
for p in "$ROOT"/prompts/*.md; do
  name="$(basename "$p")"
  target="$CODEX_HOME/prompts/$name"
  if [[ -L "$target" ]] && [[ "$(readlink -f "$target" 2>/dev/null || echo)" == "$p" ]]; then
    rm -f "$target"
  fi
done
echo "[3/4] removed StatsClaw-Codex prompt symlinks"

# 4. config.toml profiles
CONFIG="$CODEX_HOME/config.toml"
if [[ -f "$CONFIG" ]]; then
  # remove everything from the StatsClaw-Codex banner to EOF
  python3 - <<PY || true
import re, pathlib
p = pathlib.Path("$CONFIG")
s = p.read_text()
s2 = re.sub(r'\n*# --- StatsClaw-Codex profiles[\s\S]*', '\n', s)
p.write_text(s2)
PY
  echo "[4/4] stripped StatsClaw-Codex profiles from $CONFIG"
fi

if [[ $PURGE -eq 1 ]]; then
  echo "[*] purging runtime data at $DATA"
  rm -rf "$DATA"
fi

echo
echo "Done."
