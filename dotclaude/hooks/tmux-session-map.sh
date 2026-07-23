#!/bin/sh
# Claude SessionStart hook: records which conversation each tmux pane is on, so
# a post-reboot resurrect restore can put every pane back on its real session.
# See ../README.md.
#
# Must stay silent on stdout -- SessionStart stdout is injected into the
# session context.

set -u

MAP="${CLAUDE_TMUX_MAP:-${HOME}/.claude/tmux-session-map.tsv}"

[ -n "${TMUX_PANE:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

payload=$(cat 2>/dev/null) || exit 0
[ -n "$payload" ] || exit 0

session_id=$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
s = d.get("session_id")
if isinstance(s, str) and s:
    sys.stdout.write(s)
' 2>/dev/null) || exit 0
[ -n "$session_id" ] || exit 0

# Key on session:window.pane, not %N -- pane ids are not stable across a tmux
# server restart, which is exactly the case this has to survive.
coord=$(tmux display-message -p -t "$TMUX_PANE" \
    '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null) || exit 0
[ -n "$coord" ] || exit 0

cwd=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_current_path}' 2>/dev/null)
[ -n "$cwd" ] || cwd="$PWD"

umask 077

# A restore starts every pane at once.
if command -v flock >/dev/null 2>&1; then
    exec 9>"${MAP}.lock" 2>/dev/null && flock -w 2 9 2>/dev/null
fi

tmp="${MAP}.$$"
if [ -f "$MAP" ]; then
    awk -F'\t' -v c="$coord" '$1 != c' "$MAP" >"$tmp" 2>/dev/null || : >"$tmp"
else
    : >"$tmp"
fi
printf '%s\t%s\t%s\t%s\t%s\n' \
    "$coord" "$TMUX_PANE" "$cwd" "$session_id" "$(date +%s)" >>"$tmp"
mv -f "$tmp" "$MAP" 2>/dev/null || rm -f "$tmp"

exit 0
