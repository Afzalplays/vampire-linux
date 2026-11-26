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
   VAMPIRE_DRM_DIR="$TMP/dev/dri" \
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
# Configuration symlinks must not be followed.
ln -s "$TMP/etc/xdg/weston/weston.ini" "$TMP/weston-link.ini"
if VAMPIRE_WESTON_BASE="$TMP/weston-link.ini" VAMPIRE_FOOT_BASE="$TMP/etc/xdg/foot/foot.ini" VAMPIRE_DRM_DIR="$TMP/dev/dri" PATH="$TMP/bin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vgraphical" --check >/dev/null 2>&1; then
  echo "vgraphical accepted a symlinked Weston configuration" >&2
  exit 1
fi
# A symlink to a character device is not a valid DRM card node.
ln -s /dev/null "$TMP/dev/dri/card0"
if VAMPIRE_WESTON_BASE="$TMP/etc/xdg/weston/weston.ini" VAMPIRE_FOOT_BASE="$TMP/etc/xdg/foot/foot.ini" VAMPIRE_DRM_DIR="$TMP/dev/dri" PATH="$TMP/bin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vgraphical" --check >/dev/null 2>&1; then
  echo "vgraphical accepted a symlinked DRM device" >&2
  exit 1
fi
# Symlinked runtime paths must be rejected before DRM probing.
uid=$(id -u)
mkdir -p "$TMP/runtime-real"
chmod 0700 "$TMP/runtime-real"
ln -s "$TMP/runtime-real" "$TMP/runtime-link"
if VAMPIRE_RUNTIME_BASE="$TMP/runtime-link" VAMPIRE_WESTON_BASE="$TMP/etc/xdg/weston/weston.ini" VAMPIRE_FOOT_BASE="$TMP/etc/xdg/foot/foot.ini" VAMPIRE_DRM_DIR="$TMP/dev/dri" PATH="$TMP/bin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vgraphical" --check >"$TMP/runtime-base.out" 2>&1; then
  echo "vgraphical accepted a symlinked runtime base" >&2
  exit 1
fi
grep -q "refusing symlinked session runtime path" "$TMP/runtime-base.out" || {
  echo "runtime-base symlink test failed for an unexpected reason" >&2
  cat "$TMP/runtime-base.out" >&2
  exit 1
}
ln -s "$TMP/runtime-real" "$TMP/runtime-real/$uid"
if VAMPIRE_RUNTIME_BASE="$TMP/runtime-real" VAMPIRE_WESTON_BASE="$TMP/etc/xdg/weston/weston.ini" VAMPIRE_FOOT_BASE="$TMP/etc/xdg/foot/foot.ini" VAMPIRE_DRM_DIR="$TMP/dev/dri" PATH="$TMP/bin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vgraphical" --check >"$TMP/runtime-user.out" 2>&1; then
  echo "vgraphical accepted a symlinked user runtime directory" >&2
  exit 1
fi
grep -q "refusing symlinked session runtime path" "$TMP/runtime-user.out" || {
  echo "per-user runtime symlink test failed for an unexpected reason" >&2
  cat "$TMP/runtime-user.out" >&2
  exit 1
}
echo "Vampire graphical-session preflight tests passed."
