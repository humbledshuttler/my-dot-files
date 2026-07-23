#!/bin/sh
# resurrect post-restore-all hook: puts each restored pane back on the Claude
# conversation it was running before the reboot. See ../README.md.

set -u

MAP="${CLAUDE_TMUX_MAP:-${HOME}/.claude/tmux-session-map.tsv}"
LOG="${HOME}/.claude/tmux-restore-claude.log"

# Types the command but does not run it, so a reboot doesn't wake every agent
# at once. Set to 1 to auto-run.
AUTO_ENTER="${CLAUDE_RESTORE_AUTO_ENTER:-0}"

[ -f "$MAP" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

restored=0
skipped=0

while IFS="$(printf '\t')" read -r coord pane_id cwd session_id ts; do
    [ -n "${coord:-}" ] || continue
    [ -n "${session_id:-}" ] || continue

    tmux display-message -p -t "$coord" '#{pane_id}' >/dev/null 2>&1 || {
        skipped=$((skipped + 1)); continue; }

    [ -d "$cwd" ] || { skipped=$((skipped + 1)); continue; }

    # Never type over something already running.
    cur=$(tmux display-message -p -t "$coord" '#{pane_current_command}' 2>/dev/null)
    case "$cur" in
        zsh | bash | sh | fish) ;;
        *) skipped=$((skipped + 1)); continue ;;
    esac

    tmux send-keys -t "$coord" "claude --resume $session_id" 2>/dev/null
    [ "$AUTO_ENTER" = "1" ] && tmux send-keys -t "$coord" Enter 2>/dev/null
    restored=$((restored + 1))
done <"$MAP"

printf '%s restored=%s skipped=%s auto_enter=%s\n' \
    "$(date -Is)" "$restored" "$skipped" "$AUTO_ENTER" >>"$LOG" 2>/dev/null

exit 0
