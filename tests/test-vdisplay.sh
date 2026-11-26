#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SYS="$TMP/drm"
mkdir -p "$SYS/card0-eDP-1" "$SYS/card0-HDMI-A-1" "$SYS/card0-DP-1" "$TMP/external"
printf 'connected\n' > "$SYS/card0-eDP-1/status"
printf '3840x2160\n1920x1080\nnot-a-mode\n' > "$SYS/card0-eDP-1/modes"
printf 'disconnected\n' > "$SYS/card0-HDMI-A-1/status"
printf '1920x1080\n' > "$SYS/card0-HDMI-A-1/modes"
ln -s "$TMP/external" "$SYS/card0-DP-9"
OUT="$(VAMPIRE_DRM_SYSFS="$SYS" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay")"
grep -q 'eDP-1: connected' <<<"$OUT"
grep -q 'Advertised modes: 3840x2160 1920x1080' <<<"$OUT"
grep -q 'HDMI-A-1: disconnected' <<<"$OUT"\ngrep -q 'DP-1: connected' <<<"$OUT"\ngrep -q 'Mode list unavailable' <<<"$OUT"
grep -q 'Connectors: 3   Connected: 2' <<<"$OUT"
grep -q 'not a live-mode reading' <<<"$OUT"

JSON_OUT="$(VAMPIRE_DRM_SYSFS="$SYS" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" --json)"
python3 - "$JSON_OUT" <<'PY'
import json
import sys
data = json.loads(sys.argv[1])
assert data["count"] == 2, data
assert data["connected"] == 1, data
by_name = {item["name"]: item for item in data["connectors"]}
assert by_name == {
    "eDP-1": {"name": "eDP-1", "status": "connected", "modes": ["3840x2160", "1920x1080"]},
    "HDMI-A-1": {"name": "HDMI-A-1", "status": "disconnected", "modes": []},\n    "DP-1": {"name": "DP-1", "status": "connected", "modes": []},
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
ln -s "$SYS" "$TMP/drm-link"
if VAMPIRE_DRM_SYSFS="$TMP/drm-link" sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" >/dev/null 2>&1; then
  echo "vdisplay accepted a symlinked sysfs root" >&2
  exit 1
fi
if sh "$ROOT/rootfs-overlay/usr/bin/vdisplay" unexpected >/dev/null 2>&1; then
  echo "vdisplay accepted an unknown argument" >&2
  exit 1
fi
echo "Vampire display inventory and JSON tests passed."
