#!/usr/bin/env bash
#
# Install the Chrome auto-updater: symlink the script into /usr/local/bin and
# enable the systemd timer that runs it once a day.
#
#   ./install.sh          symlink the script (tracks git pulls)
#   ./install.sh --copy   copy the script instead (root-owned, not user-writable)
#   ./install.sh --uninstall

set -euo pipefail

SRC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN=/usr/local/bin/chrome-auto-update
UNIT_DIR=/etc/systemd/system
MODE=symlink

case "${1:-}" in
    --copy) MODE=copy ;;
    --uninstall) MODE=uninstall ;;
    "") ;;
    *)
        echo "usage: $0 [--copy | --uninstall]" >&2
        exit 1
        ;;
esac

if [ "$MODE" = uninstall ]; then
    sudo systemctl disable --now chrome-auto-update.timer 2>/dev/null || true
    sudo rm -f "$UNIT_DIR/chrome-auto-update.timer" \
        "$UNIT_DIR/chrome-auto-update.service" "$BIN"
    sudo systemctl daemon-reload
    echo "Chrome auto-updater removed."
    exit 0
fi

chmod +x "$SRC_DIR/chrome-auto-update.sh"

sudo rm -f "$BIN"
if [ "$MODE" = copy ]; then
    sudo install -m 0755 -o root -g root "$SRC_DIR/chrome-auto-update.sh" "$BIN"
    echo "Installed $BIN (copy)"
else
    sudo ln -s "$SRC_DIR/chrome-auto-update.sh" "$BIN"
    echo "Installed $BIN -> $SRC_DIR/chrome-auto-update.sh"
fi

sudo install -m 0644 -o root -g root \
    "$SRC_DIR/chrome-auto-update.service" "$UNIT_DIR/chrome-auto-update.service"
sudo install -m 0644 -o root -g root \
    "$SRC_DIR/chrome-auto-update.timer" "$UNIT_DIR/chrome-auto-update.timer"

sudo systemctl daemon-reload
sudo systemctl enable --now chrome-auto-update.timer

echo
echo "Timer enabled. Next run:"
systemctl list-timers chrome-auto-update.timer --no-pager
echo
echo "Run it now:   sudo systemctl start chrome-auto-update.service"
echo "See the log:  journalctl -u chrome-auto-update.service -n 50"
