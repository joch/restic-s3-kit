#!/usr/bin/env bash
set -euo pipefail
KIT_DIR="/opt/restic"
CONF_DIR="$KIT_DIR/config"

# Bootstrap binary if missing
if [ ! -x "$KIT_DIR/bin/restic" ]; then
  echo "restic binary not found; bootstrapping..."
  sudo "$KIT_DIR/bin/bootstrap-restic.sh"
fi

# Seed example env if missing
if [ ! -f "$CONF_DIR/restic.env" ] && [ -f "$CONF_DIR/restic.env.example" ]; then
  sudo cp "$CONF_DIR/restic.env.example" "$CONF_DIR/restic.env"
  echo "Created $CONF_DIR/restic.env from example; edit it before enabling timers."
fi

sudo install -d -m 0700 /var/cache/restic
sudo chmod 600 "$CONF_DIR/password"
sudo chmod 640 "$CONF_DIR/restic.env" || true
sudo chown root:root "$CONF_DIR/password"
sudo chown root:root "$CONF_DIR/restic.env" || true

sudo cp "$KIT_DIR/systemd/restic-backup.service" /etc/systemd/system/
sudo cp "$KIT_DIR/systemd/restic-backup.timer" /etc/systemd/system/
sudo cp "$KIT_DIR/systemd/restic-prune.service" /etc/systemd/system/
sudo cp "$KIT_DIR/systemd/restic-prune.timer" /etc/systemd/system/
sudo cp "$KIT_DIR/systemd/restic-check.service" /etc/systemd/system/
sudo cp "$KIT_DIR/systemd/restic-check.timer" /etc/systemd/system/
sudo systemctl daemon-reload

echo "Installed. Edit $CONF_DIR/restic.env, $CONF_DIR/password, and $CONF_DIR/paths.list, then:"
echo "  systemctl enable --now restic-backup.timer restic-prune.timer restic-check.timer"
