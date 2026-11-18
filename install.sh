#!/bin/bash
# MCF Battery Health — installer. Run as your normal user; it asks for sudo once.
set -euo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ME=${SUDO_USER:-$USER}
[[ $ME == root ]] && { echo "Run install.sh as your normal user, not root." >&2; exit 1; }

found=0
for b in /sys/class/power_supply/BAT*; do
  [[ -f $b/charge_control_end_threshold ]] && found=1
done
(( found )) || { echo "No battery with charge-limit support found; nothing to install." >&2; exit 1; }

echo "Installing MCF Battery Health for user '$ME' (sudo needed once)…"

# Root-owned pieces: helper, sudoers rule, auto-heal service and udev rule.
sudo install -d -m 755 /usr/local/libexec/mcf-battery-health
sudo install -m 755 -o root -g root "$SRC/libexec/helper" /usr/local/libexec/mcf-battery-health/helper
sudo install -d -m 755 /var/lib/mcf-battery-health

tmp=$(mktemp)
printf '%s ALL=(root) NOPASSWD: /usr/local/libexec/mcf-battery-health/helper limit, /usr/local/libexec/mcf-battery-health/helper full, /usr/local/libexec/mcf-battery-health/helper bypass, /usr/local/libexec/mcf-battery-health/helper drain\n' "$ME" >"$tmp"
sudo visudo -cf "$tmp" >/dev/null || { rm -f "$tmp"; echo "sudoers rule failed validation; aborting." >&2; exit 1; }
sudo install -m 440 -o root -g root "$tmp" /etc/sudoers.d/mcf-battery-health
rm -f "$tmp"

sudo install -m 644 "$SRC/system/mcf-battery-health-restore.service" /etc/systemd/system/
sudo install -m 644 "$SRC/system/90-mcf-battery-health.rules" /etc/udev/rules.d/
sudo systemctl daemon-reload
sudo systemctl enable mcf-battery-health-restore.service >/dev/null
sudo udevadm control --reload

# Only one thing should manage the thresholds: switch off UPower's own
# charge-limit handling if it was turned on, so it can't undo our choice at boot.
gdbus call --system --dest org.freedesktop.UPower \
  --object-path /org/freedesktop/UPower/devices/battery_BAT0 \
  --method org.freedesktop.UPower.Device.EnableChargeThreshold false >/dev/null 2>&1 || true

# User-side: the menu script and the app-launcher entry.
install -d "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/icons/hicolor/scalable/apps"
install -m 644 "$SRC/mcf-battery-health.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/mcf-battery-health.svg"
install -m 755 "$SRC/bin/mcf-battery-health" "$HOME/.local/bin/mcf-battery-health"
sed "s|@BIN@|$HOME/.local/bin/mcf-battery-health|" "$SRC/mcf-battery-health.desktop" \
  >"$HOME/.local/share/applications/mcf-battery-health.desktop"
command -v update-desktop-database >/dev/null &&
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# Start out limited to 80%.
sudo -n /usr/local/libexec/mcf-battery-health/helper limit

b=$(ls -d /sys/class/power_supply/BAT* | head -1)
echo "Done. Battery limit is now $(cat "$b/charge_control_start_threshold" 2>/dev/null)–$(cat "$b/charge_control_end_threshold")%."
echo "Open it from the app launcher: search for \"battery\"."
