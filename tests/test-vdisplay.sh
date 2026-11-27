#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SYS="$TMP/drm"
mkdir -p "$SYS/card0-eDP-1" "$SYS/card0-HDMI-A-1" "$SYS/card0-DP-1" "$SYS/card0-DP-2" "$SYS/card0-DP-3" "$TMP/external"
printf 'connected\n' > "$SYS/card0-eDP-1/status"
printf '3840x2160\n1920x1080\nnot-a-mode\n' > "$SYS/card0-eDP-1/modes"
printf 'disconnected\n' > "$SYS/card0-HDMI-A-1/status"
printf '1920x1080\n' > "$SYS/card0-HDMI-A-1/modes"
printf 'connected\n' > "$SYS/card0-DP-1/status"
ln -s "$TMP/external" "$SYS/card0-DP-1/modes"
ln -s "$TMP/external" "$SYS/card0-DP-2/status"
printf 'unknown\n' > "$SYS/card0-DP-3/status"
ln -s "$TMP/external" "$SYS/card0-DP-9"
OUT="$(VAMPIRE_DRM_SYSFS="$SYS" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay")"
grep -q 'eDP-1: connected' <<<"$OUT"
grep -q 'Advertised modes: 3840x2160 1920x1080' <<<"$OUT"
grep -q 'HDMI-A-1: disconnected' <<<"$OUT"
grep -q 'DP-1: connected' <<<"$OUT"
grep -q 'Mode list unavailable' <<<"$OUT"
grep -q 'Connectors: 3   Connected: 2' <<<"$OUT"
grep -q 'not a live-mode reading' <<<"$OUT"
! grep -q 'DP-2:' <<<"$OUT"
! grep -q 'DP-3:' <<<"$OUT"

JSON_OUT="$(VAMPIRE_DRM_SYSFS="$SYS" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" --json)"
python3 - "$JSON_OUT" <<'PY'
import json
import sys
data = json.loads(sys.argv[1])
assert data["count"] == 3, data
assert data["connected"] == 2, data
by_name = {item["name"]: item for item in data["connectors"]}
assert by_name == {
    "eDP-1": {"name": "eDP-1", "status": "connected", "modes": ["3840x2160", "1920x1080"]},
    "HDMI-A-1": {"name": "HDMI-A-1", "status": "disconnected", "modes": []},
    "DP-1": {"name": "DP-1", "status": "connected", "modes": []},
}, data
PY

EMPTY="$TMP/empty"
mkdir "$EMPTY"
VAMPIRE_DRM_SYSFS="$EMPTY" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" | grep -q 'No DRM display connectors found'
EMPTY_JSON="$(VAMPIRE_DRM_SYSFS="$EMPTY" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" --json)"
python3 - "$EMPTY_JSON" <<'PY'
import json
import sys
assert json.loads(sys.argv[1]) == {"connectors": [], "count": 0, "connected": 0}
PY
sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" --help | grep -q -- '--json'
ln -s "$SYS" "$TMP/drm-link"
if VAMPIRE_DRM_SYSFS="$TMP/drm-link" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" >/dev/null 2>&1; then
  echo "vdisplay accepted a symlinked sysfs root" >&2
  exit 1
fi
if sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" unexpected >/dev/null 2>&1; then
  echo "vdisplay accepted an unknown argument" >&2
  exit 1
fi
if sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" --json unexpected >/dev/null 2>&1; then
  echo "vdisplay accepted extra arguments after --json" >&2
  exit 1
fi
# Accept the canonical /sys/class/drm -> /sys/devices connector link shape.
DEVICES="$TMP/devices"
mkdir -p "$DEVICES/pci0000:00/card0-DP-4"
printf 'connected\n' > "$DEVICES/pci0000:00/card0-DP-4/status"
printf '3200x1800\n' > "$DEVICES/pci0000:00/card0-DP-4/modes"
ln -s "$DEVICES/pci0000:00/card0-DP-4" "$SYS/card0-DP-4"
LINKED_OUT="$(VAMPIRE_DRM_SYSFS="$SYS" VAMPIRE_SYSFS_DEVICES_ROOT="$DEVICES" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay")"
grep -q 'DP-4: connected' <<<"$LINKED_OUT"
grep -q 'DP-4: connected' <<<"$(VAMPIRE_DRM_SYSFS="$SYS" VAMPIRE_SYSFS_DEVICES_ROOT="$DEVICES" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" --json)"
echo "Vampire display inventory, JSON and unsafe-entry tests passed."
