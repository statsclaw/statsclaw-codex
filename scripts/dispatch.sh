#!/usr/bin/env bash
#
# scripts/dispatch.sh — StatsClaw-Codex sub-agent dispatch wrapper
#
# Wraps `codex exec` to invoke a specialist teammate from the leader's main
# session. Handles frontmatter parsing, worktree isolation for writer teammates,
# and merge-back on success.
#
# Usage:
#   scripts/dispatch.sh <role> <run-dir> [--worktree] [--task "<task prompt>"] \
#                       [--target-repo <path>] [--profile <codex-profile>]
#
# Example:
#   scripts/dispatch.sh builder \
#       "$STATSCLAW_CODEX_DATA/workspace/fect/runs/REQ-0042" \
#       --worktree \
#       --target-repo "$STATSCLAW_CODEX_DATA/fect" \
#       --task "Implement spec.md into R/ivreg.R and tests/testthat/test-ivreg.R"
#
# Environment:
#   STATSCLAW_CODEX_ROOT — framework root (set by install.sh)
#   STATSCLAW_CODEX_DATA — runtime data dir (default: ~/.codex/data/statsclaw)
#
# Exit codes:
#   0  success (teammate completed, artifacts written, worktree merged)
#   2  bad arguments
#   3  missing agent definition
#   4  codex exec failed
#   5  worktree merge-back failed

set -euo pipefail

ROOT="${STATSCLAW_CODEX_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DATA="${STATSCLAW_CODEX_DATA:-$HOME/.codex/data/statsclaw}"
mkdir -p "$DATA/worktrees"

ROLE=""
RUN_DIR=""
USE_WORKTREE=0
TASK=""
TARGET_REPO=""
PROFILE_OVERRIDE=""

die() { echo "dispatch: $*" >&2; exit "${2:-2}"; }

usage() {
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

# Positional: role, run-dir
[[ $# -lt 2 ]] && usage
ROLE="$1"; shift
RUN_DIR="$1"; shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worktree)    USE_WORKTREE=1; shift ;;
    --task)        TASK="$2"; shift 2 ;;
    --target-repo) TARGET_REPO="$2"; shift 2 ;;
    --profile)     PROFILE_OVERRIDE="$2"; shift 2 ;;
    -h|--help)     usage ;;
    *)             die "unknown argument: $1" 2 ;;
  esac
done

AGENT_FILE="$ROOT/agents/${ROLE}.md"
[[ -f "$AGENT_FILE" ]] || die "agent definition not found: $AGENT_FILE" 3
[[ -d "$RUN_DIR" ]]    || die "run directory does not exist: $RUN_DIR" 2

# --- Parse frontmatter (model, profile, isolation) -------------------------
get_front() {
  awk -v k="$1:" '/^---$/{n++; next} n==1 && $0 ~ "^"k{sub("^"k" *","",$0); print; exit}' "$AGENT_FILE"
}
FRONT_MODEL="$(get_front model || true)"
FRONT_PROFILE="$(get_front profile || true)"
FRONT_ISOLATION="$(get_front isolation || true)"

CODEX_PROFILE="${PROFILE_OVERRIDE:-${FRONT_PROFILE:-statsclaw-$ROLE}}"

if [[ "$FRONT_ISOLATION" == "worktree" ]] && [[ $USE_WORKTREE -eq 0 ]]; then
  # Frontmatter says worktree but caller forgot — infer it.
  USE_WORKTREE=1
fi

# --- Worktree setup --------------------------------------------------------
WORKTREE_PATH=""
ORIGINAL_BRANCH=""
if [[ $USE_WORKTREE -eq 1 ]]; then
  [[ -n "$TARGET_REPO" ]] || die "--worktree requires --target-repo <path>" 2
  [[ -d "$TARGET_REPO/.git" ]] || die "target-repo is not a git repo: $TARGET_REPO" 2

  REQUEST_ID="$(basename "$RUN_DIR")"
  WORKTREE_PATH="$DATA/worktrees/${ROLE}-${REQUEST_ID}"
  ORIGINAL_BRANCH="$(git -C "$TARGET_REPO" symbolic-ref --short HEAD)"

  if [[ -d "$WORKTREE_PATH" ]]; then
    echo "dispatch: reusing existing worktree $WORKTREE_PATH" >&2
  else
    git -C "$TARGET_REPO" worktree add -B "statsclaw/${ROLE}/${REQUEST_ID}" \
        "$WORKTREE_PATH" "$ORIGINAL_BRANCH" >&2
  fi
  WORK_CWD="$WORKTREE_PATH"
else
  WORK_CWD="${TARGET_REPO:-$PWD}"
fi

# --- Build teammate prompt -------------------------------------------------
PROMPT="$(cat <<EOF
You are the ${ROLE} teammate in a StatsClaw-Codex workflow.

Read your agent definition at ${AGENT_FILE} and follow its rules exactly.

## Context
- StatsClaw-Codex framework root: ${ROOT}
- StatsClaw-Codex runtime data:   ${DATA}
- Target repo working directory:  ${WORK_CWD}
- Run directory:                  ${RUN_DIR}
- Codex profile:                  ${CODEX_PROFILE}
- Isolation:                      $([[ $USE_WORKTREE -eq 1 ]] && echo "worktree @ ${WORKTREE_PATH}" || echo "none (read-only or non-writer role)")

## Your Task
${TASK:-See request.md, impact.md, and your agent definition for the task.}

## Required Inputs (read these first)
- ${RUN_DIR}/request.md
- ${RUN_DIR}/impact.md
- (role-specific artifacts as defined in ${AGENT_FILE})

## Required Output
Write your artifact to ${RUN_DIR}/<role-artifact>.md per your agent definition.

## Key Rules
- Only modify files within your assigned write surface.
- Do NOT modify status.md — leader will update it.
- Append to mailbox.md if you encounter blockers or interface changes.
$(if [[ $USE_WORKTREE -eq 1 ]]; then
cat <<EOF2
- **WORKTREE ISOLATION**: You are running inside a git worktree at ${WORKTREE_PATH}.
  You MUST \`git add\` and \`git commit\` all your changes within this worktree
  BEFORE returning. If you do not commit, your changes will be permanently
  discarded when the worktree is cleaned up. Do NOT push — only commit locally.
EOF2
fi)
EOF
)"

# --- Invoke Codex ----------------------------------------------------------
echo "dispatch: role=$ROLE profile=$CODEX_PROFILE isolation=$([[ $USE_WORKTREE -eq 1 ]] && echo worktree || echo none)" >&2

codex exec \
  --profile "$CODEX_PROFILE" \
  --full-auto \
  --cd "$WORK_CWD" \
  "$PROMPT" \
  || { EC=$?; die "codex exec failed (exit $EC)" 4; }

# --- Worktree merge-back ---------------------------------------------------
if [[ $USE_WORKTREE -eq 1 ]]; then
  # Confirm the teammate committed something.
  BRANCH="statsclaw/${ROLE}/${REQUEST_ID}"
  if ! git -C "$TARGET_REPO" rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
    die "worktree branch $BRANCH vanished — teammate may not have committed" 5
  fi

  COMMITS_AHEAD="$(git -C "$TARGET_REPO" rev-list --count "$ORIGINAL_BRANCH..$BRANCH")"
  if [[ "$COMMITS_AHEAD" == "0" ]]; then
    echo "dispatch: WARNING — teammate committed no new changes in worktree" >&2
    git -C "$TARGET_REPO" worktree remove --force "$WORKTREE_PATH" || true
    git -C "$TARGET_REPO" branch -D "$BRANCH" 2>/dev/null || true
    exit 0
  fi

  # Fast-forward merge onto the original branch.
  git -C "$TARGET_REPO" merge --ff-only "$BRANCH" \
    || die "fast-forward merge-back failed (non-ff); leaving worktree in place" 5

  git -C "$TARGET_REPO" worktree remove --force "$WORKTREE_PATH" || true
  git -C "$TARGET_REPO" branch -D "$BRANCH" 2>/dev/null || true
  echo "dispatch: merged $COMMITS_AHEAD commit(s) from worktree back onto $ORIGINAL_BRANCH" >&2
fi

exit 0
