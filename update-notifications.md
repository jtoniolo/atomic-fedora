# Update Notification Investigation

## Current State

The workstation image has automatic updates enabled via Universal Blue's `uupd` system:

- **Timer**: `uupd.timer` runs every 6 hours (enabled by default)
- **Behavior**: Downloads and stages updates silently, queued for next reboot
- **Problem**: No desktop notification when updates are staged - user must check manually

## Checking for Updates

```bash
# Manual check (shows staged updates)
rpm-ostree status

# Check if update available (requires sudo, exit code 77 = no update)
sudo uupd update-check

# Interactive check with more detail
rpm-ostree update --check
rpm-ostree update --preview
```

## Built-in Tools (No Notification Support)

### uupd (Universal Blue Update Daemon)
- Location: `/usr/bin/uupd`
- Config: `/etc/uupd/config.json`
- Logs: `journalctl -exu 'uupd.service'`
- **No notification support** - runs silently in background

### rpm-ostreed-automatic
- Alternative to uupd (disabled when uupd is enabled)
- Policies: `none`, `check`, `stage`, `apply`
- Config: `/etc/rpm-ostreed.conf` with `AutomaticUpdatePolicy=`
- **No notification support**

### Plasma Discover Notifier
- Package `plasma-discover-notifier` is installed
- **Disabled** on Aurora images (all .desktop files have `.disabled` suffix)
- May not integrate well with rpm-ostree anyway

## ujust Commands

```bash
# Toggle automatic updates on/off
ujust toggle-updates

# Manual update (system + flatpaks + containers)
ujust update
```

## Proposed Solution (Not Implemented)

Add a login script that checks for staged updates and sends a desktop notification:

**Script** (`/usr/local/bin/check-staged-updates`):
```bash
#!/bin/bash
if rpm-ostree status | grep -q "pending"; then
    notify-send -a "System Update" "Update staged" "Reboot when convenient"
fi
```

**Autostart** (`/etc/xdg/autostart/check-staged-updates.desktop`):
```ini
[Desktop Entry]
Type=Application
Name=Check Staged Updates
Exec=/usr/local/bin/check-staged-updates
X-GNOME-Autostart-Phase=Applications
```

To add to image recipe, place files in:
- `files/system/usr/local/bin/check-staged-updates`
- `files/system/etc/xdg/autostart/check-staged-updates.desktop`

## Related Links

- uupd: https://github.com/ublue-os/uupd
- rpm-ostree automatic updates: `man rpm-ostreed.conf`
- BlueBuild files module: https://blue-build.org/reference/modules/files/
