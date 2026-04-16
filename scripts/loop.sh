#!/usr/bin/env bash
#
# scripts/loop.sh — recurring /loop executor for StatsClaw-Codex
#
# Backs the /loop slash command (prompts/loop.md). The slash command expands
# into a call to this script with the parsed interval and inner prompt.
#
# Usage:
#   scripts/loop.sh <interval> <inner-prompt>
#
# Interval grammar (same as upstream /loop skill):
#   5m, 30m, 1h, 1h30m, 2d
#
# Example:
#   scripts/loop.sh 30m "patrol fect issues on cfe"
#
# Each iteration invokes:
#   codex exec --profile statsclaw-leader --full-auto "<inner-prompt>"
#
# Iterations continue until the script is killed (Ctrl-C, SIGTERM) or the
# inner command emits an explicit STOP marker on stdout.

set -euo pipefail

INTERVAL="${1:-10m}"
INNER="${2:-}"
[[ -n "$INNER" ]] || { echo "usage: $0 <interval> <inner-prompt>" >&2; exit 2; }

parse_seconds() {
  local s="$1" total=0 n
  while [[ -n "$s" ]]; do
    n="${s%%[dhms]*}"; s="${s:${#n}}"
    case "${s:0:1}" in
      d) total=$((total + n*86400));;
      h) total=$((total + n*3600));;
      m) total=$((total + n*60));;
      s) total=$((total + n));;
      *) echo "bad interval: $1" >&2; exit 2;;
    esac
    s="${s:1}"
  done
  echo "$total"
}

SECS="$(parse_seconds "$INTERVAL")"
[[ $SECS -ge 60 ]] || { echo "interval must be >= 60s" >&2; exit 2; }

echo "loop: interval=${INTERVAL} (${SECS}s) inner='${INNER}'"
trap 'echo "loop: stopped"; exit 0' INT TERM

while :; do
  TS="$(date -u +%FT%TZ)"
  echo "loop: tick @ ${TS}"
  if codex exec --profile statsclaw-leader --full-auto "$INNER" | tee /tmp/statsclaw-loop-last.log; then
    if grep -q '^LOOP:STOP$' /tmp/statsclaw-loop-last.log 2>/dev/null; then
      echo "loop: inner emitted STOP marker — exiting"
      exit 0
    fi
  else
    echo "loop: inner command failed (non-zero exit) — continuing to next tick"
  fi
  echo "loop: sleeping ${SECS}s"
  sleep "$SECS"
done
