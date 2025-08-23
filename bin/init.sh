#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/opt/restic/config/restic.env"
PASS_FILE="/opt/restic/config/password"
RESTIC_BIN="/opt/restic/bin/restic"

# Requirements
[ -x "$RESTIC_BIN" ] || { echo "restic binary not found at $RESTIC_BIN; run /opt/restic/bin/bootstrap-restic.sh"; exit 1; }
[ -f "$ENV_FILE" ]   || { echo "Missing $ENV_FILE"; exit 1; }
[ -f "$PASS_FILE" ]  || { echo "Missing $PASS_FILE"; exit 1; }

# Load env and export what restic needs
# shellcheck disable=SC1090
source "$ENV_FILE"

export RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-$PASS_FILE}"
export RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-}"

# Pass-through common AWS/S3 vars if set
for v in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_DEFAULT_REGION AWS_S3_BUCKET_LOOKUP RESTIC_CACHE_DIR; do
  val="${!v-}"
  [ -n "${val:-}" ] && export "$v"="$val"
done

: "${RESTIC_REPOSITORY:?Set RESTIC_REPOSITORY in $ENV_FILE}"

echo "Repository: $RESTIC_REPOSITORY"

# If repo already exists, exit quietly
if "$RESTIC_BIN" -r "$RESTIC_REPOSITORY" cat config >/dev/null 2>&1; then
  echo "Repository already initialized."
  exit 0
fi

echo "Initializing restic repository at $RESTIC_REPOSITORY ..."
"$RESTIC_BIN" -r "$RESTIC_REPOSITORY" init
echo "Done."

