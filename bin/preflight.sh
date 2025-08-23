#!/usr/bin/env bash
set -euo pipefail
ENV_FILE="/opt/restic/config/restic.env"
PASS_FILE="/opt/restic/config/password"
PATHS_FILE="/opt/restic/config/paths.list"
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
echo "== Preflight: dependencies =="
need curl; need bunzip2; need sha256sum
echo "== Preflight: restic binary =="
if [ ! -x /opt/restic/bin/restic ]; then
  echo "restic not installed; run /opt/restic/bin/bootstrap-restic.sh" >&2; exit 1
fi
/opt/restic/bin/restic version
echo "== Preflight: config files =="
[ -f "$ENV_FILE" ] || { echo "Missing $ENV_FILE"; exit 1; }
[ -f "$PASS_FILE" ] || { echo "Missing $PASS_FILE"; exit 1; }
[ -f "$PATHS_FILE" ] || { echo "Missing $PATHS_FILE"; exit 1; }
# Basic sanity: at least one non-comment, non-empty line in paths.list
if ! grep -E '^[[:space:]]*[^#[:space:]].*$' "$PATHS_FILE" >/dev/null 2>&1; then
  echo "No usable paths in $PATHS_FILE"; exit 1
fi
# shellcheck disable=SC1090
source "$ENV_FILE"
echo "== Preflight: required env =="
: "${RESTIC_REPOSITORY:?Set in $ENV_FILE}"
: "${AWS_ACCESS_KEY_ID:?Set in $ENV_FILE}"
: "${AWS_SECRET_ACCESS_KEY:?Set in $ENV_FILE}"
echo "== Preflight: endpoint connectivity =="
host=$(echo "$RESTIC_REPOSITORY" | sed -n 's#^s3:https://\([^/]*\)/.*#\1#p')
if [ -n "$host" ]; then
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://$host")
  echo "HTTP code: $code"
fi
echo "== Preflight: repo accessibility =="
if ! /opt/restic/bin/restic snapshots >/dev/null 2>&1; then
  echo "No snapshots yet or repo not initialized. Initialize with:"
  echo "  RESTIC_PASSWORD_FILE=$PASS_FILE /opt/restic/bin/restic init"
fi
echo "Preflight OK."
