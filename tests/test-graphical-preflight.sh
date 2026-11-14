#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/etc/xdg/weston" "$TMP/etc/xdg/foot" "$TMP/dev/dri"
cat > "$TMP/bin/weston" <<'MOCK'
#!/bin/sh
exit 0
MOCK
cat > "$TMP/bin/foot" <<'MOCK'
#!/bin/sh
exit 0
MOCK
chmod +x "$TMP/bin/weston" "$TMP/bin/foot"
: > "$TMP/etc/xdg/weston/weston.ini"
: > "$TMP/etc/xdg/foot/foot.ini"
# A regular file is intentionally not accepted as a DRM character device.
if VAMPIRE_WESTON_BASE="$TMP/etc/xdg/weston/weston.ini" \
   VAMPIRE_FOOT_BASE="$TMP/etc/xdg/foot/foot.ini" \
   VAMPIRE_DRM_DIR="$TMP/dev/dri" \\
   PATH="$TMP/bin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vgraphical" --check >/dev/null 2>&1; then
  echo "vgraphical accepted a missing DRM device" >&2
  exit 1
fi
if "$ROOT/rootfs-overlay/usr/bin/vgraphical" --unknown >/dev/null 2>&1; then
  echo "vgraphical accepted an unknown argument" >&2
  exit 1
fi
"$ROOT/rootfs-overlay/usr/bin/vgraphical" --help | grep -q -- '--check'
grep -q 'modprobe "$module"' "$ROOT/rootfs-overlay/usr/bin/vgraphical"
echo "Vampire graphical-session preflight tests passed."
