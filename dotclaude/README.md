# dotclaude

Claude Code configuration that should follow the user across machines.

## Dependencies

- `tmux` — installed by `install.sh`
- `claude` (Claude Code) — **not** installed by `install.sh`; install it separately.
  The hooks no-op safely if it is missing.
- `python3` — used by the SessionStart hook and by `merge-settings-hooks.py`

## What this does

Restores Claude conversations into the right tmux panes after a reboot.

`tmux-resurrect` saves the pane layout and working directories, but not running
processes — a restored pane comes back as a bare shell. These two hooks close
that gap:

1. **`hooks/tmux-session-map.sh`** — a Claude `SessionStart` hook. Records
   `session:window.pane → session id` into `~/.claude/tmux-session-map.tsv`
   every time a session starts, resumes, or compacts.

2. **`hooks/tmux-restore-claude.sh`** — a `tmux-resurrect`
   `@resurrect-hook-post-restore-all` hook (wired in `../dottmux.conf`). After a
   restore it types `claude --resume <id>` into each matching pane.

The map is keyed on `session:window.pane` rather than the `%N` pane id, because
`%N` is not stable across a tmux server restart.

## Installation

Handled by the repo's `install.sh`:

- symlinks `hooks/*.sh` into `~/.claude/hooks/`
- merges `settings.hooks.json` into `~/.claude/settings.json` via
  `merge-settings-hooks.py`

`~/.claude/settings.json` is deliberately **not** symlinked — it also carries
machine-local state (permission allowlists with absolute paths, enabled
plugins), so only the hook entries are merged in.

## Behaviour notes

- The restore hook **types the command but does not press Enter**, so a reboot
  does not launch every agent at once. Set `CLAUDE_RESTORE_AUTO_ENTER=1` to run
  them automatically.
- It skips panes whose recorded directory no longer exists, and never types
  into a pane that already has something running.
- `tmux-session-map.sh` must stay silent on stdout — `SessionStart` hook stdout
  is injected into the session context.
- `~/.claude/tmux-session-map.tsv` is machine-local and not tracked here.

## Manual check

    # what is mapped right now
    column -t -s"$(printf '\t')" ~/.claude/tmux-session-map.tsv

    # dry-run the restore against the live server (types nothing without a restore)
    sh hooks/tmux-restore-claude.sh && tail -1 ~/.claude/tmux-restore-claude.log
