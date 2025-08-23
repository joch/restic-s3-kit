#!/usr/bin/env bash
set -euo pipefail
sudo systemctl disable --now restic-backup.timer restic-prune.timer restic-check.timer || true
sudo systemctl stop restic-backup.service restic-prune.service restic-check.service || true
sudo rm -f /etc/systemd/system/restic-backup.service
sudo rm -f /etc/systemd/system/restic-backup.timer
sudo rm -f /etc/systemd/system/restic-prune.service
sudo rm -f /etc/systemd/system/restic-prune.timer
sudo rm -f /etc/systemd/system/restic-check.service
sudo rm -f /etc/systemd/system/restic-check.timer
sudo systemctl daemon-reload
echo "Uninstalled systemd units. Kit remains at /opt/restic."
