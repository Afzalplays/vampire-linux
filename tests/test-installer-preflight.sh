#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SYS="$TMP/sys/block"; DEV="$TMP/dev"; MOUNTS="$TMP/mounts"
mkdir -p "$SYS/vda/device" "$SYS/vda/vda1" "$DEV"
: > "$DEV/vda"; : > "$DEV/vda1"
printf '41943040\n' > "$SYS/vda/size"
printf '0\n' > "$SYS/vda/ro"
printf '0\n' > "$SYS/vda/removable"
printf 'Vampire Test Disk\n' > "$SYS/vda/device/model"
printf '1\n' > "$SYS/vda/vda1/partition"
: > "$MOUNTS"
export VAMPIRE_SYS_BLOCK="$SYS" VAMPIRE_DEV_ROOT="$DEV" VAMPIRE_MOUNTS_FILE="$MOUNTS"
sh "$ROOT/rootfs-overlay/usr/bin/vinstall" list | grep -q 'Vampire Test Disk'
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" list | grep -q 'vda1'; then
  echo "partition was incorrectly listed as a whole disk" >&2; exit 1
fi
sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" | grep -q 'basic checks passed'
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda1" >"$TMP/out" 2>&1; then
  echo "partition unexpectedly accepted as whole disk" >&2; exit 1
fi
grep -q 'whole disk' "$TMP/out"
printf '%s\n' "$DEV/vda1 / ext4 rw 0 0" > "$MOUNTS"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "mounted device unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'mounted at /' "$TMP/out"
mkdir -p "$DEV/disk/by-id"
ln -s "$DEV/vda1" "$DEV/disk/by-id/vampire-test-partition"
printf '%s\n' "$DEV/disk/by-id/vampire-test-partition / ext4 rw 0 0" > "$MOUNTS"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "mounted aliased partition unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'mounted at /' "$TMP/out"
# Enforce the minimum target capacity and make removable-media status visible.
printf '8388608\n' > "$SYS/vda/size"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "undersized target unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'smaller than the 8 GiB minimum' "$TMP/out"
printf '41943040\n' > "$SYS/vda/size"
: > "$MOUNTS"
printf '1\n' > "$SYS/vda/removable"
sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out"
grep -q 'marked as removable media' "$TMP/out"
grep -q 'basic checks passed' "$TMP/out"
printf '0\n' > "$SYS/vda/removable"
# If mount information is unavailable, the installer must fail closed.
rm -f "$MOUNTS"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "preflight unexpectedly passed without a mount table" >&2; exit 1
fi
grep -q 'mount table unavailable' "$TMP/out"
: > "$MOUNTS"
printf '1\n' > "$SYS/vda/ro"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "read-only device unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'read-only' "$TMP/out"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/../bad" >/dev/null 2>&1; then
  echo "invalid device path unexpectedly accepted" >&2; exit 1
fi
# The readiness check must reject non-x86_64 images before presenting the
# installer as usable. Stub uname without changing the host environment.
mkdir -p "$TMP/fakebin"
cat > "$TMP/fakebin/uname" <<'EOF'
#!/bin/sh
echo aarch64
EOF
chmod +x "$TMP/fakebin/uname"
if PATH="$TMP/fakebin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vinstall" system-check >"$TMP/out" 2>&1; then
  echo "non-x86_64 image unexpectedly passed installer system check" >&2; exit 1
fi
grep -q 'targets x86_64/AMD64' "$TMP/out"
cat > "$TMP/fakebin/uname" <<'EOF'
#!/bin/sh
echo x86_64
EOF
chmod +x "$TMP/fakebin/uname"
PATH="$TMP/fakebin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vinstall" system-check >"$TMP/out"
grep -q 'Architecture: x86_64' "$TMP/out"
grep -q 'diagnostic only' "$TMP/out"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" system-check extra >/dev/null 2>&1; then
  echo "system-check unexpectedly accepted extra arguments" >&2; exit 1
fi
echo "Vampire installer preflight tests passed."
