# MCF Battery Health

Set your laptop's battery charging mode from a popup menu, then forget about it.
No bar icon and nothing running in the background.

Open it from the app launcher: press **Super+Space** and search **battery**.

| Option | What it does |
|---|---|
| **Limit to 80%** | Holds the battery between 75% and 80%. Best for all-day docking. |
| **Full charge** | Charges to 100%, for a day away from the desk. Stays this way until you pick Limit again. |
| **Bypass** | Runs on dock/charger power without charging the battery at all. |
| **Drain to 80%** | Runs off the battery while docked until it reaches 80%, then switches to Limit. |
| **Status** | Notification with charge, thresholds, battery health, cycle count and the last auto-fix. |

Bypass and Drain only appear if your battery supports them.

## Auto-heal

Whenever the dock or charger is plugged in or out, and at boot, your chosen
mode is quietly re-applied. If a BIOS update or firmware reset puts the limit
back to 100%, it's fixed the next time you dock, and the date shows under Status.
A deliberate **Full charge** is respected until you change it.

## Install

```sh
./install.sh
```

Run as your normal user; it asks for sudo once. It starts you on **Limit to 80%**.

It installs:

- `~/.local/bin/mcf-battery-health`: the menu
- `~/.local/share/applications/mcf-battery-health.desktop` plus icon: the app-launcher entry
- `/usr/local/libexec/mcf-battery-health/helper`: the root helper, the only thing that writes battery settings
- `/etc/sudoers.d/mcf-battery-health`: lets the helper run without a password, for those four actions only
- `/etc/systemd/system/mcf-battery-health-restore.service` and `/etc/udev/rules.d/90-mcf-battery-health.rules`: auto-heal

It also switches off UPower's own charge-limit handling, so two tools aren't
fighting over the same setting.

## Uninstall

```sh
./uninstall.sh
```

Leaves the battery limited to 80%.

## Troubleshooting

```sh
journalctl -t mcf-battery-health       # auto-heal and drain log
cat /sys/class/power_supply/BAT0/charge_control_{start,end}_threshold
cat /sys/class/power_supply/BAT0/charge_behaviour
```

MIT licensed.
