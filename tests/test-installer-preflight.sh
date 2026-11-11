#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SYS="$TMP/sys/block"; DEV="$TMP/dev"; MOUNTS="$TMP/mounts"
mkdir -p "$SYS/vda/device" "$DEV"
: > "$DEV/vda"
printf '41943040\n' > "$SYS/vda/size"
printf '0\n' > "$SYS/vda/ro"
printf '0\n' > "$SYS/vda/removable"
printf 'Vampire Test Disk\n' > "$SYS/vda/device/model"
: > "$MOUNTS"
export VAMPIRE_SYS_BLOCK="$SYS" VAMPIRE_DEV_ROOT="$DEV" VAMPIRE_MOUNTS_FILE="$MOUNTS"
sh "$ROOT/rootfs-overlay/usr/bin/vinstall" list | grep -q 'Vampire Test Disk'
sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" | grep -q 'basic checks passed'
printf '%s\n' "$DEV/vda1 / ext4 rw 0 0" > "$MOUNTS"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "mounted device unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'mounted at /' "$TMP/out"
printf '1\n' > "$SYS/vda/ro"; : > "$MOUNTS"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "read-only device unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'read-only' "$TMP/out"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/../bad" >/dev/null 2>&1; then
  echo "invalid device path unexpectedly accepted" >&2; exit 1
fi
echo "Vampire installer preflight tests passed."
