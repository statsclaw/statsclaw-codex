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
AGENTS_MARKETPLACE="$HOME/.agents/plugins/marketplace.json"
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
  echo "[1/6] removed env vars from $ENV_FILE"
fi

# 2. AGENTS.md import
GLOBAL_AGENTS="$CODEX_HOME/AGENTS.md"
if [[ -f "$GLOBAL_AGENTS" ]]; then
  sed -i.bak "\|@$ROOT/AGENTS.md|d" "$GLOBAL_AGENTS"
  rm -f "$GLOBAL_AGENTS.bak"
  echo "[2/6] removed AGENTS.md import from $GLOBAL_AGENTS"
fi

# 3. legacy prompt symlinks (older installers created these — clean them up if
#    they exist and still point at this checkout).
if [[ -d "$CODEX_HOME/prompts" ]]; then
  legacy_removed=0
  for p in "$ROOT"/prompts/*.md; do
    [[ -e "$p" ]] || continue
    name="$(basename "$p")"
    target="$CODEX_HOME/prompts/$name"
    if [[ -L "$target" ]] && [[ "$(readlink -f "$target" 2>/dev/null || echo)" == "$p" ]]; then
      rm -f "$target"
      legacy_removed=$((legacy_removed + 1))
    fi
  done
  echo "[3/6] removed $legacy_removed legacy prompt symlink(s) from $CODEX_HOME/prompts/"
fi

# 4. config.toml profiles
CONFIG="$CODEX_HOME/config.toml"
if [[ -f "$CONFIG" ]]; then
  python3 - <<PY || true
import re, pathlib
p = pathlib.Path("$CONFIG")
s = p.read_text()
s2 = re.sub(r'\n*# --- StatsClaw-Codex profiles[\s\S]*', '\n', s)
p.write_text(s2)
PY
  echo "[4/6] stripped StatsClaw-Codex profiles from $CONFIG"
fi

# 5. marketplace.json
if [[ -f "$AGENTS_MARKETPLACE" ]]; then
  # Only delete the file if it's the single-plugin StatsClaw marketplace we wrote.
  # If the user has added other plugins, leave it alone and tell them.
  if grep -q '"name": "statsclaw"' "$AGENTS_MARKETPLACE" && \
     [ "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["plugins"]))' "$AGENTS_MARKETPLACE" 2>/dev/null)" = "1" ]; then
    rm -f "$AGENTS_MARKETPLACE"
    echo "[5/6] removed $AGENTS_MARKETPLACE"
    # remove empty .agents/plugins and .agents dirs if they're now empty
    rmdir "$HOME/.agents/plugins" "$HOME/.agents" 2>/dev/null || true
  else
    echo "[5/6] left $AGENTS_MARKETPLACE in place — it has other plugins registered. Remove the 'statsclaw' entry manually if desired."
  fi
fi

# 6. shell-rc hooks
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  [[ -f "$rc" ]] || continue
  if grep -qF "# StatsClaw-Codex" "$rc"; then
    sed -i.bak '/# StatsClaw-Codex/d' "$rc"
    rm -f "$rc.bak"
    echo "[6/6] removed shell-rc hook from $rc"
  fi
done

if [[ $PURGE -eq 1 ]]; then
  echo "[*] purging runtime data at $DATA"
  rm -rf "$DATA"
fi

echo
echo "Done."
