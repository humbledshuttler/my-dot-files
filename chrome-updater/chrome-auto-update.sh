#!/usr/bin/env bash
#
# Keep Google Chrome up to date from Google's own apt repository.
#
# Chrome ships with an apt source (/etc/apt/sources.list.d/google-chrome.sources),
# so there is no need to download .deb files by hand - this refreshes just that
# one repository and upgrades just that one package.
#
# Runs as root, normally from chrome-auto-update.timer once a day.
# Manual run: sudo chrome-auto-update

set -euo pipefail

PKG=google-chrome-stable
CHROME_SOURCE=/etc/apt/sources.list.d/google-chrome.sources
CHROME_SOURCE_LEGACY=/etc/apt/sources.list.d/google-chrome.list

# Wait rather than fail if apt-daily or another apt run holds the dpkg lock.
APT_OPTS=(-o DPkg::Lock::Timeout=600)

log() { echo "[chrome-auto-update] $*"; }

if [ "$(id -u)" -ne 0 ]; then
    log "must run as root (try: sudo chrome-auto-update)"
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    log "apt-get not found - this script only supports Debian/Ubuntu systems"
    exit 1
fi

if ! dpkg-query -W -f='${Status}' "$PKG" 2>/dev/null | grep -q '^install ok installed$'; then
    log "$PKG is not installed - nothing to do"
    exit 0
fi

# Refresh package lists for the Chrome repo only. Copying the source file into a
# temp dir and pointing apt at it keeps this fast and avoids hammering every other
# repo on the machine. List-Cleanup=0 stops apt from discarding the cached lists
# of the repos we deliberately left out.
refresh_chrome_lists() {
    local tmpdir found=0 f
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' RETURN

    for f in "$CHROME_SOURCE" "$CHROME_SOURCE_LEGACY"; do
        if [ -f "$f" ]; then
            cp "$f" "$tmpdir/"
            found=1
        fi
    done

    if [ "$found" -eq 0 ]; then
        log "no Google Chrome apt source found - falling back to a full apt-get update"
        apt-get "${APT_OPTS[@]}" update -qq
        return
    fi

    apt-get "${APT_OPTS[@]}" update -qq \
        -o Dir::Etc::sourcelist=/dev/null \
        -o Dir::Etc::sourceparts="$tmpdir" \
        -o APT::Get::List-Cleanup=0
}

# Best-effort desktop notification so you know to relaunch Chrome.
notify_desktop() {
    local msg="$1" session type uid user
    command -v notify-send >/dev/null 2>&1 || return 0
    command -v loginctl >/dev/null 2>&1 || return 0

    while read -r session; do
        [ -n "$session" ] || continue
        type=$(loginctl show-session "$session" -p Type --value 2>/dev/null || true)
        case "$type" in
            wayland | x11) ;;
            *) continue ;;
        esac
        uid=$(loginctl show-session "$session" -p User --value 2>/dev/null || true)
        user=$(loginctl show-session "$session" -p Name --value 2>/dev/null || true)
        [ -n "$uid" ] && [ -n "$user" ] || continue

        sudo -u "$user" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            notify-send -a "Chrome updater" "Google Chrome updated" "$msg" \
            >/dev/null 2>&1 || true
    done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
}

refresh_chrome_lists

installed=$(dpkg-query -W -f='${Version}' "$PKG")
candidate=$(apt-cache policy "$PKG" | awk '/Candidate:/ {print $2}')

if [ -z "$candidate" ] || [ "$candidate" = "(none)" ]; then
    log "could not determine candidate version - is the Chrome repo reachable?"
    exit 1
fi

if [ "$installed" = "$candidate" ]; then
    log "already up to date ($installed)"
    exit 0
fi

log "updating $PKG: $installed -> $candidate"

DEBIAN_FRONTEND=noninteractive apt-get "${APT_OPTS[@]}" install -y --only-upgrade \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold \
    "$PKG"

now=$(dpkg-query -W -f='${Version}' "$PKG")
log "updated $PKG to $now"

if pgrep -x chrome >/dev/null 2>&1 || pgrep -f '/opt/google/chrome/chrome' >/dev/null 2>&1; then
    log "Chrome is running - relaunch it to finish applying $now"
    notify_desktop "Updated to $now. Relaunch Chrome to apply it."
else
    notify_desktop "Updated to $now."
fi
