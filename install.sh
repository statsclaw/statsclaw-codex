#!/usr/bin/env bash
#
# install.sh — register StatsClaw-Codex with the user's Codex CLI
#
# Behaviour (idempotent — safe to re-run):
#   1. Writes STATSCLAW_CODEX_ROOT + STATSCLAW_CODEX_DATA + PATH into ~/.codex/env.sh
#   2. Adds `@<root>/AGENTS.md` import to ~/.codex/AGENTS.md
#   3. Merges [profiles.statsclaw-*] blocks from codex-config.example.toml into ~/.codex/config.toml
#   4. Creates ${STATSCLAW_CODEX_DATA}/ runtime dir
#   5. Installs a user-scoped marketplace JSON at ~/.agents/plugins/marketplace.json
#      so `codex /plugins` can discover and install the statsclaw plugin.
#   6. Hooks `source ~/.codex/env.sh` into the user's shell rc (~/.bashrc, ~/.zshrc).
#
# Flags:
#   --no-shell-hook   skip step 6
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
DATA="${STATSCLAW_CODEX_DATA:-$CODEX_HOME/data/statsclaw}"
AGENTS_MARKETPLACE_DIR="$HOME/.agents/plugins"
AGENTS_MARKETPLACE="$AGENTS_MARKETPLACE_DIR/marketplace.json"
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
echo "  marketplace:    $AGENTS_MARKETPLACE"
echo

mkdir -p "$DATA/workspace" "$DATA/worktrees" "$AGENTS_MARKETPLACE_DIR"

# 1. env.sh --------------------------------------------------------------
ENV_FILE="$CODEX_HOME/env.sh"
mkdir -p "$CODEX_HOME"
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

# 3. config.toml profiles ------------------------------------------------
CONFIG="$CODEX_HOME/config.toml"
EXAMPLE="$ROOT/codex-config.example.toml"
touch "$CONFIG"
if ! grep -q '\[profiles\.statsclaw-leader\]' "$CONFIG"; then
  {
    echo ""
    echo "# --- StatsClaw-Codex profiles (added by install.sh) ---"
    sed -n '/^# ==== StatsClaw-Codex profiles/,$p' "$EXAMPLE"
  } >> "$CONFIG"
  echo "[3/6] appended StatsClaw-Codex profiles to $CONFIG"
else
  echo "[3/6] StatsClaw-Codex profiles already present in $CONFIG — leaving untouched"
fi

# 4. runtime dir ---------------------------------------------------------
echo "[4/6] runtime data dir ready at $DATA"

# 5. Codex marketplace ---------------------------------------------------
# Register a user-scoped marketplace.json that points at this checkout as a
# local plugin source. Codex CLI's `/plugins` browser will pick it up.
write_marketplace() {
  cat > "$AGENTS_MARKETPLACE" <<EOF
{
  "name": "statsclaw",
  "interface": {
    "displayName": "StatsClaw",
    "shortDescription": "User-scoped local marketplace for StatsClaw-Codex"
  },
  "plugins": [
    {
      "name": "statsclaw",
      "source": {
        "source": "local",
        "path": "$ROOT"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Research"
    }
  ]
}
EOF
}

if [[ -f "$AGENTS_MARKETPLACE" ]]; then
  if grep -q '"name": "statsclaw"' "$AGENTS_MARKETPLACE" && grep -q "\"$ROOT\"" "$AGENTS_MARKETPLACE"; then
    echo "[5/6] marketplace already registered at $AGENTS_MARKETPLACE"
  else
    cp "$AGENTS_MARKETPLACE" "$AGENTS_MARKETPLACE.bak.$(date +%s)"
    write_marketplace
    echo "[5/6] rewrote marketplace at $AGENTS_MARKETPLACE (previous saved as *.bak.*)"
    echo "      if you had OTHER plugins registered, merge them back manually from the backup."
  fi
else
  write_marketplace
  echo "[5/6] registered StatsClaw marketplace at $AGENTS_MARKETPLACE"
fi

# 6. shell-rc hook -------------------------------------------------------
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
  hooked=0
  if [[ -f "$HOME/.bashrc" ]]; then
    hook_into "$HOME/.bashrc" && hooked=1
  fi
  if [[ -f "$HOME/.zshrc" ]]; then
    hook_into "$HOME/.zshrc" && hooked=1
  fi
  if [[ $hooked -eq 0 ]]; then
    touch "$HOME/.profile"
    hook_into "$HOME/.profile"
  fi
  echo "[6/6] shell-rc hook installed — new shells auto-load the env"
  if (return 0 2>/dev/null); then
    # shellcheck disable=SC1090
    . "$ENV_FILE"
  fi
else
  echo "[6/6] skipping shell-rc hook (--no-shell-hook)"
fi

cat <<EOF

Done. Next steps:

  1. Open a NEW terminal (or run: source $ENV_FILE)
  2. Run:   codex
  3. Inside Codex:   /plugins           # browse the marketplace
                     install statsclaw  # install the plugin
  4. Then trigger any skill:
       \$patrol <owner/repo>         # issue patrol
       \$simulate <description>      # Monte Carlo study
       \$ship-it                     # push reviewed changes
       \$review                      # ship/no-ship verdict
       \$contribute                  # submit session knowledge to the brain
       \$brain on | off | status     # manage brain mode
       \$loop <interval> <cmd>       # recurring execution

Natural language also works — Codex matches the skill description.
E.g. "patrol open issues on xuyiqing/fect" auto-triggers \$patrol.
EOF
