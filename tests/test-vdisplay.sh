#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SYS="$TMP/drm"
mkdir -p "$SYS/card0-eDP-1" "$SYS/card0-HDMI-A-1" "$TMP/external"
printf 'connected\n' > "$SYS/card0-eDP-1/status"
printf '3840x2160\n1920x1080\nnot-a-mode\n' > "$SYS/card0-eDP-1/modes"
printf 'disconnected\n' > "$SYS/card0-HDMI-A-1/status"
printf '1920x1080\n' > "$SYS/card0-HDMI-A-1/modes"
ln -s "$TMP/external" "$SYS/card0-DP-9"
OUT="$(VAMPIRE_DRM_SYSFS="$SYS" "$ROOT/rootfs-overlay/usr/bin/vdisplay")"
grep -q 'eDP-1: connected' <<<"$OUT"
grep -q 'Advertised modes: 3840x2160 1920x1080' <<<"$OUT"
grep -q 'HDMI-A-1: disconnected' <<<"$OUT"
grep -q 'Connectors: 2   Connected: 1' <<<"$OUT"
grep -q 'not a live-mode reading' <<<"$OUT"
EMPTY="$TMP/empty"
mkdir "$EMPTY"
VAMPIRE_DRM_SYSFS="$EMPTY" "$ROOT/rootfs-overlay/usr/bin/vdisplay" | grep -q 'No DRM display connectors found'
ln -s "$SYS" "$TMP/drm-link"
if VAMPIRE_DRM_SYSFS="$TMP/drm-link" "$ROOT/rootfs-overlay/usr/bin/vdisplay" >/dev/null 2>&1; then
  echo "vdisplay accepted a symlinked sysfs root" >&2
  exit 1
fi
if "$ROOT/rootfs-overlay/usr/bin/vdisplay" unexpected >/dev/null 2>&1; then
  echo "vdisplay accepted an unknown argument" >&2
  exit 1
fi
echo "Vampire display inventory tests passed."
