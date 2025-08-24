# restic-s3-kit

> Zero-fuss self-contained **restic** backups to any S3‑compatible storage.

## Requirements
- Linux with systemd
- `curl`, `bunzip2`, `sha256sum`
- Installed into `/opt/restic` - update scripts otherwise

## Install
```bash
# 1) Deploy kit (git or download manually)
sudo git clone https://github.com/joch/restic-s3-kit.git /opt/restic/

# 2) Fetch the restic binary
sudo /opt/restic/bin/download-restic.sh

# 3) Copy sample configuration
sudo cp -r /opt/restic/config.sample /opt/restic/config

# 4) Configure: endpoint, keys, password, and paths

sudoedit /opt/restic/config/restic.env          # set S3 endpoint + keys
sudoedit /opt/restic/config/password            # repo password (one line, mode 0600)
sudoedit /opt/restic/config/paths.list          # one path per line

# 5) (Optional) Initialize a brand-new repo
sudo /opt/restic/bin/init.sh

# 6) Sanity check
sudo /opt/restic/bin/preflight.sh

# 7) Install units & start timers
sudo /opt/restic/bin/install.sh
sudo systemctl enable --now restic-backup.timer restic-prune.timer restic-check.timer
```

## Minimal config (generic S3‑compatible)
`/opt/restic/config/restic.env`:
```bash
# S3-compatible endpoint (examples: Wasabi/Hetzner/AWS/R2/MinIO/etc.)
RESTIC_REPOSITORY=s3:https://<endpoint-host>/<bucket>/<optional/prefix>
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_S3_BUCKET_LOOKUP=dns

# Common settings
RESTIC_CACHE_DIR=/var/cache/restic
RESTIC_PASSWORD_FILE=/opt/restic/config/password

# Optional snapshot metadata
HOSTNAME_OVERRIDE=""         # e.g. "web-1"
TAGS=""                      # space-separated -> --tag entries

# Excludes + policy
EXCLUDES_FILE=/opt/restic/config/excludes.list
FORGET_ARGS="--keep-daily 14 --keep-weekly 8 --keep-monthly 12"
EXTRA_FORGET_ARGS=""
EXTRA_BACKUP_ARGS=""
CHECK_READ_SUBSET="1/50"     # ~2% data read on weekly check
```

## Choose what to back up
`/opt/restic/config/paths.list` — one path per line. Comments (`# ...`) and blank lines are ok.
```
/etc
/home
/srv
# /var/lib/postgresql
```

## Schedule (defaults)
- **Daily backup**: `OnCalendar=daily` (+ ~20m jitter)  
- **Weekly check**: Sunday ~03:00 (+ jitter), reads subset (`CHECK_READ_SUBSET`)  
- **Monthly prune**: `OnCalendar=monthly`

Change times in `opt/restic/systemd/*.timer` before running `install.sh` if you like.

## Access the restic command (with configuration applied)
- `sudo /opt/restic/bin/restic-exec`

## Troubleshooting
- Logs: `journalctl -u restic-backup -n 200 --no-pager`
- Force a run: `sudo systemctl start restic-backup.service`
- See snapshots: `sudo /opt/restic/bin/restic-exec snapshots`
- Pin a version: `RESTIC_VERSION=vX.Y.Z /opt/restic/bin/download-restic.sh`

## Uninstall
```bash
sudo /opt/restic/bin/uninstall.sh
```

## License
MIT — see `LICENSE`.
