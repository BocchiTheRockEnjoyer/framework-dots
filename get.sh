#!/usr/bin/env bash
# Framework Dots: downloads the theme to a temporary folder and starts its installer.
# It asks before changing anything. Options are passed on to install.sh.
set -euo pipefail

main() {
  local url="${FD_URL:-https://github.com/BocchiTheRockEnjoyer/framework-dots/archive/refs/heads/main.tar.gz}" c
  [ "$(id -u)" -ne 0 ] || { echo "Run this as yourself, not with sudo."; exit 1; }
  for c in curl tar gzip; do command -v "$c" >/dev/null || { echo "Please install '$c' first."; exit 1; }; done
  if [ -n "${KDE_SESSION_VERSION:-}" ] && [ "$KDE_SESSION_VERSION" != 6 ]; then echo "This needs KDE Plasma 6. Nothing was downloaded."; exit 1; fi
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  echo "Downloading Framework Dots (about 13 MB) ..."
  curl -fL --progress-bar -o "$tmp/theme.tar.gz" "$url" || { echo "The download failed. Nothing was changed."; exit 1; }
  mkdir "$tmp/theme"
  tar -xzf "$tmp/theme.tar.gz" -C "$tmp/theme" --strip-components=1 || { echo "The download was damaged. Nothing was changed."; exit 1; }
  [ -f "$tmp/theme/install.sh" ] || { echo "The download is missing the installer. Nothing was changed."; exit 1; }
  # When piped into bash, the keyboard has to be asked for separately
  if [ ! -t 0 ] && { : </dev/tty; } 2>/dev/null; then bash "$tmp/theme/install.sh" "$@" </dev/tty
  else bash "$tmp/theme/install.sh" "$@"; fi
}
# Everything is in a function, so a half-finished download can't run
main "$@"
