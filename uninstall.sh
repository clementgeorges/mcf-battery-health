#!/bin/bash
# MCF Battery Health — uninstaller. Leaves the battery limited to 80%.
set -uo pipefail

echo "Removing MCF Battery Health (sudo needed once)…"
sudo systemctl stop mcf-battery-health-drain.timer 2>/dev/null || true
sudo /usr/local/libexec/mcf-battery-health/helper limit 2>/dev/null || true
sudo systemctl disable mcf-battery-health-restore.service >/dev/null 2>&1 || true
sudo rm -f /etc/systemd/system/mcf-battery-health-restore.service \
  /etc/udev/rules.d/90-mcf-battery-health.rules \
  /etc/sudoers.d/mcf-battery-health
sudo rm -rf /usr/local/libexec/mcf-battery-health /var/lib/mcf-battery-health
sudo systemctl daemon-reload
sudo udevadm control --reload

rm -f "$HOME/.local/bin/mcf-battery-health" "$HOME/.local/share/applications/mcf-battery-health.desktop" \
  "$HOME/.local/share/icons/hicolor/scalable/apps/mcf-battery-health.svg"
command -v update-desktop-database >/dev/null &&
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "Removed. The battery stays limited to 75–80% (the firmware keeps it);"
echo "to allow 100% again: echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold"
