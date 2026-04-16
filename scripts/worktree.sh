#!/usr/bin/env bash
#
# scripts/worktree.sh — standalone git worktree helper for StatsClaw-Codex
#
# Most workflows don't need this directly — scripts/dispatch.sh creates and
# merges back worktrees automatically. This helper is for manual recovery
# (e.g., if a teammate crashed and the worktree needs inspection or cleanup).
#
# Usage:
#   scripts/worktree.sh list <target-repo>
#   scripts/worktree.sh inspect <target-repo> <role> <request-id>
#   scripts/worktree.sh merge   <target-repo> <role> <request-id>
#   scripts/worktree.sh clean   <target-repo> <role> <request-id>
#   scripts/worktree.sh clean-all <target-repo>

set -euo pipefail

DATA="${STATSCLAW_CODEX_DATA:-$HOME/.codex/data/statsclaw}"

die() { echo "worktree: $*" >&2; exit 1; }

cmd="${1:-}"; shift || true
case "$cmd" in
  list)
    [[ $# -ge 1 ]] || die "usage: worktree.sh list <target-repo>"
    git -C "$1" worktree list
    ;;
  inspect)
    [[ $# -ge 3 ]] || die "usage: worktree.sh inspect <target-repo> <role> <request-id>"
    WT="$DATA/worktrees/$2-$3"
    [[ -d "$WT" ]] || die "no such worktree: $WT"
    echo "path:   $WT"
    echo "branch: $(git -C "$WT" symbolic-ref --short HEAD 2>/dev/null || echo '(detached)')"
    echo "status:"
    git -C "$WT" status --short
    echo "log:"
    git -C "$WT" log --oneline -10
    ;;
  merge)
    [[ $# -ge 3 ]] || die "usage: worktree.sh merge <target-repo> <role> <request-id>"
    TARGET="$1"; ROLE="$2"; REQ="$3"
    WT="$DATA/worktrees/$ROLE-$REQ"
    BRANCH="statsclaw/$ROLE/$REQ"
    [[ -d "$WT" ]] || die "no such worktree: $WT"
    ORIG="$(git -C "$TARGET" symbolic-ref --short HEAD)"
    git -C "$TARGET" merge --ff-only "$BRANCH" \
      || die "fast-forward merge failed (non-ff) — resolve manually"
    git -C "$TARGET" worktree remove --force "$WT"
    git -C "$TARGET" branch -D "$BRANCH" 2>/dev/null || true
    echo "merged $BRANCH onto $ORIG and cleaned up"
    ;;
  clean)
    [[ $# -ge 3 ]] || die "usage: worktree.sh clean <target-repo> <role> <request-id>"
    TARGET="$1"; ROLE="$2"; REQ="$3"
    WT="$DATA/worktrees/$ROLE-$REQ"
    BRANCH="statsclaw/$ROLE/$REQ"
    [[ -d "$WT" ]] && git -C "$TARGET" worktree remove --force "$WT" || true
    git -C "$TARGET" branch -D "$BRANCH" 2>/dev/null || true
    echo "cleaned worktree $WT (discarded uncommitted changes)"
    ;;
  clean-all)
    [[ $# -ge 1 ]] || die "usage: worktree.sh clean-all <target-repo>"
    TARGET="$1"
    git -C "$TARGET" worktree list --porcelain \
      | awk '/^worktree/ {print $2}' \
      | grep "$DATA/worktrees/" || { echo "no stale worktrees"; exit 0; }
    for wt in $(git -C "$TARGET" worktree list --porcelain | awk '/^worktree/ {print $2}' | grep "$DATA/worktrees/"); do
      git -C "$TARGET" worktree remove --force "$wt" || true
    done
    git -C "$TARGET" branch --list 'statsclaw/*' | xargs -r -n1 git -C "$TARGET" branch -D
    echo "all stale StatsClaw-Codex worktrees cleaned"
    ;;
  ""|-h|--help)
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *)
    die "unknown command: $cmd"
    ;;
esac
