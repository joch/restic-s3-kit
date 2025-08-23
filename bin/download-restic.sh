#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="/opt/restic/bin"
TARGET="${BIN_DIR}/restic"
mkdir -p "$BIN_DIR"

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux) os="linux" ;;
  Darwin) os="darwin" ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  armv7l|armv7) arch="arm" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

tag="${RESTIC_VERSION:-}"
if [ -z "$tag" ]; then
  API="https://api.github.com/repos/restic/restic/releases/latest"
  tag="$(curl -sSL "$API" | grep -oP '"tag_name":\s*"\K[^"]+' || true)"
  if [ -z "$tag" ]; then
    echo "Could not determine latest restic version from GitHub API." >&2
    exit 1
  fi
fi

base="https://github.com/restic/restic/releases/download/${tag}"
file="restic_${tag#v}_${os}_${arch}.bz2"
sumfile="SHA256SUMS"
ascfile="SHA256SUMS.asc"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading ${file} (tag ${tag})..."
curl -fL "$base/$file" -o "$tmp/$file"
curl -fL "$base/$sumfile" -o "$tmp/$sumfile"

if [ "${VERIFY_GPG:-0}" = "1" ] && command -v gpg >/dev/null 2>&1; then
  echo "Downloading signature and verifying GPG..."
  curl -fL "$base/$ascfile" -o "$tmp/$ascfile"
  gpg --keyserver hkps://keys.openpgp.org --recv-keys 2F11749EEE28C6AA3C2F059F9B3E3D9A2F11749E || true
  gpg --verify "$tmp/$ascfile" "$tmp/$sumfile"
fi

echo "Verifying checksum..."
( cd "$tmp" && sha256sum -c <(grep " $file$" "$sumfile") )

echo "Decompressing..."
bunzip2 -c "$tmp/$file" > "$TARGET"
chmod +x "$TARGET"

echo "Installed $TARGET -> $("$TARGET" version)"
