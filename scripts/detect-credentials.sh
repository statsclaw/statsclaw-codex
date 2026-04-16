#!/usr/bin/env bash
#
# scripts/detect-credentials.sh — GitHub credential auto-detection for StatsClaw-Codex
#
# Implements the detection sequence from skills/credential-setup/SKILL.md:
#   1. GITHUB_TOKEN environment variable
#   2. gh auth status (GitHub CLI)
#   3. SSH key + ssh-agent (git@github.com probe)
#   4. git credential helper
#   5. otherwise: ASK USER
#
# Writes a credentials.md fragment to stdout; exits 0 on PASS, 1 on FAIL,
# 2 on ASK (caller should surface the missing-credentials message to the user).
#
# Usage:
#   scripts/detect-credentials.sh <target-repo-url> [<workspace-repo-url>]
#
# Example:
#   scripts/detect-credentials.sh https://github.com/xuyiqing/fect https://github.com/alice/workspace

set -euo pipefail

TARGET_URL="${1:-}"
WORKSPACE_URL="${2:-}"

[[ -n "$TARGET_URL" ]] || { echo "usage: $0 <target-repo-url> [<workspace-repo-url>]" >&2; exit 2; }

detect_one() {
  local url="$1" label="$2"
  local method="none"
  local result="FAIL"
  local detail=""

  # 1. GITHUB_TOKEN
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    if curl -fsSL -o /dev/null -H "Authorization: token $GITHUB_TOKEN" \
         "https://api.github.com/repos/$(echo "$url" | sed -E 's|.*github.com[:/]||; s|\.git$||')" 2>/dev/null; then
      method="GITHUB_TOKEN"
      result="PASS"
      detail="api.github.com reachable via \$GITHUB_TOKEN"
    fi
  fi

  # 2. gh CLI
  if [[ "$result" == "FAIL" ]] && command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      method="gh-cli"
      result="PASS"
      detail="$(gh auth status 2>&1 | head -3 | tr '\n' '; ')"
    fi
  fi

  # 3. SSH
  if [[ "$result" == "FAIL" ]]; then
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
      method="ssh"
      result="PASS"
      detail="git@github.com SSH key accepted"
    fi
  fi

  # 4. git credential helper
  if [[ "$result" == "FAIL" ]]; then
    local helper
    helper="$(git config --global credential.helper || true)"
    if [[ -n "$helper" ]]; then
      method="git-credential-$helper"
      result="MAYBE"
      detail="credential helper configured ($helper) — push will be attempted"
    fi
  fi

  echo "### $label"
  echo "- **URL:** $url"
  echo "- **Method:** $method"
  echo "- **Result:** $result"
  echo "- **Detail:** ${detail:-none}"
  echo
  [[ "$result" == "PASS" || "$result" == "MAYBE" ]]
}

{
  echo "# credentials.md — StatsClaw-Codex push access probe"
  echo
  echo "_Generated: $(date -u +%FT%TZ)_"
  echo

  TARGET_OK=0
  WS_OK=0
  detect_one "$TARGET_URL" "Target repo" && TARGET_OK=1 || true
  if [[ -n "$WORKSPACE_URL" ]]; then
    detect_one "$WORKSPACE_URL" "Workspace repo" && WS_OK=1 || true
  fi

  echo "## Verdict"
  if [[ $TARGET_OK -eq 1 ]]; then
    echo "- Target repo: **PASS** — workflow may proceed"
  else
    echo "- Target repo: **FAIL** — block run; ask user for PAT or SSH key"
  fi
  if [[ -n "$WORKSPACE_URL" ]]; then
    if [[ $WS_OK -eq 1 ]]; then
      echo "- Workspace repo: **PASS** — workflow logs will sync"
    else
      echo "- Workspace repo: **FAIL (warning only)** — workflow proceeds, logs do NOT sync"
    fi
  fi
}

[[ $TARGET_OK -eq 1 ]]
