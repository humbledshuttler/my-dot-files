# Chrome auto-updater

Keeps Google Chrome current so you never have to click through to the download
page and install a `.deb` by hand.

Chrome's own installer already adds Google's apt repository at
`/etc/apt/sources.list.d/google-chrome.sources`, so the new version is normally
sitting there waiting - it just never gets installed unless you run apt. This
does that once a day.

## Install

```sh
./install.sh
```

That symlinks `chrome-auto-update.sh` to `/usr/local/bin/chrome-auto-update`,
installs the systemd units, and enables the timer.

## What it does

`chrome-auto-update.sh` (run as root by the timer):

1. Refreshes package lists for the Chrome repo **only** - fast, and it doesn't
   disturb the cached lists of your other repos.
2. Compares the installed version against the candidate.
3. If they differ, runs `apt-get install --only-upgrade google-chrome-stable`.
4. Sends a desktop notification, and tells you to relaunch if Chrome is running.

It waits up to 10 minutes for the dpkg lock, so it won't fail just because
`apt-daily` happens to be running.

## Schedule

`chrome-auto-update.timer` fires daily at 12:00 local time with up to 30 minutes
of random jitter. `Persistent=true` means a day missed because the machine was
off gets picked up shortly after the next boot.

Change the time by editing `chrome-auto-update.timer` and re-running
`./install.sh`.

## Useful commands

```sh
sudo systemctl start chrome-auto-update.service   # run now
journalctl -u chrome-auto-update.service -n 50    # see what happened
systemctl list-timers chrome-auto-update.timer    # when's next
sudo chrome-auto-update                           # run the script directly
./install.sh --uninstall                          # remove everything
```

## Note on the symlink

The default install symlinks into `/usr/local/bin`, matching how the rest of
this repo installs `dev-tools/`, so `git pull` picks up changes automatically.
The tradeoff is that root runs a script living in a directory your normal user
can write to. On a single-user machine that's the same trust boundary you
already have; if you'd rather not, `./install.sh --copy` installs a root-owned
copy instead (re-run it after changing the script).
