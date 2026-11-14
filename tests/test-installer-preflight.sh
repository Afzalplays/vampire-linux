#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SYS="$TMP/sys/block"; DEV="$TMP/dev"; MOUNTS="$TMP/mounts"; MOUNTINFO="$TMP/mountinfo"; SWAPS="$TMP/swaps"
mkdir -p "$SYS/vda/device" "$SYS/vda/vda1" "$SYS/vda/holders" "$SYS/vda/vda1/holders" "$DEV"
: > "$DEV/vda"; : > "$DEV/vda1"
printf '41943040\n' > "$SYS/vda/size"
printf '0\n' > "$SYS/vda/ro"
printf '0\n' > "$SYS/vda/removable"
printf 'Vampire Test Disk\n' > "$SYS/vda/device/model"
printf '1\n' > "$SYS/vda/vda1/partition"
printf '8:0\n' > "$SYS/vda/dev"
printf '8:1\n' > "$SYS/vda/vda1/dev"
: > "$MOUNTS"; : > "$MOUNTINFO"
printf 'Filename Type Size Used Priority\n' > "$SWAPS"
export VAMPIRE_SYS_BLOCK="$SYS" VAMPIRE_DEV_ROOT="$DEV" VAMPIRE_MOUNTS_FILE="$MOUNTS" VAMPIRE_MOUNTINFO_FILE="$MOUNTINFO" VAMPIRE_SWAPS_FILE="$SWAPS"
sh "$ROOT/rootfs-overlay/usr/bin/vinstall" list | grep -q 'Vampire Test Disk'
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" list | grep -q 'vda1'; then
  echo "partition was incorrectly listed as a whole disk" >&2; exit 1
fi
sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" | grep -q 'basic checks passed'
# Layout planning must remain read-only and cover both firmware modes.
sh "$ROOT/rootfs-overlay/usr/bin/vinstall" plan "$DEV/vda" uefi >"$TMP/plan"
grep -q 'Partition table: GPT' "$TMP/plan"
grep -q '512 MiB  EFI System Partition (FAT32)' "$TMP/plan"
grep -q 'Remaining space  Linux filesystem (ext4)' "$TMP/plan"
grep -q 'No partition table was written' "$TMP/plan"
sh "$ROOT/rootfs-overlay/usr/bin/vinstall" plan "$DEV/vda" bios >"$TMP/plan"
grep -q '2 MiB  BIOS boot partition' "$TMP/plan"
grep -q 'Remaining space  Linux filesystem (ext4)' "$TMP/plan"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" plan "$DEV/vda" legacy >"$TMP/out" 2>&1; then
  echo "invalid firmware mode unexpectedly accepted" >&2; exit 1
fi
grep -q 'firmware mode must be uefi or bios' "$TMP/out"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" plan "$DEV/vda1" uefi >"$TMP/out" 2>&1; then
  echo "partition unexpectedly accepted by layout planner" >&2; exit 1
fi
grep -q 'whole disk' "$TMP/out"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda1" >"$TMP/out" 2>&1; then
  echo "partition unexpectedly accepted as whole disk" >&2; exit 1
fi
grep -q 'whole disk' "$TMP/out"
printf '%s\n' "$DEV/vda1 / ext4 rw 0 0" > "$MOUNTS"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "mounted device unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'mounted at /' "$TMP/out"
# Mountinfo major:minor catches aliases and bind-mounted block sources even
# when /proc/mounts uses a different device path.
printf '42 1 8:1 / /mnt/alias rw - ext4 /dev/disk/by-id/alias rw\n' > "$MOUNTINFO"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "mounted major:minor alias unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'major:minor 8:1' "$TMP/out"
: > "$MOUNTINFO"
# Active swap is not visible in the mount table and must block the target.
printf '%s partition 1024 0 -2\n' "$DEV/vda1" >> "$SWAPS"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "active swap partition unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'active swap' "$TMP/out"
: > "$SWAPS"; printf 'Filename Type Size Used Priority\n' > "$SWAPS"
# A disk already backing LVM/RAID/device-mapper must not be overwritten.
: > "$SYS/vda/holders/dm-0"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "stacked block device unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'stacked block device' "$TMP/out"
rm -f "$SYS/vda/holders/dm-0"
# A whole-disk source must also block preflight, not only child partitions.
printf '%s %s ext4 rw 0 0\n' "$DEV/vda" "/mnt/whole-disk" > "$MOUNTS"
if sh "$ROOT/rootfs-overlay/usr/bin/vinstall" preflight "$DEV/vda" >"$TMP/out" 2>&1; then
  echo "mounted whole disk unexpectedly passed preflight" >&2; exit 1
fi
grep -q 'mounted at /mnt/whole-disk' "$TMP/out"
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
grep -q 'mount, mountinfo or swap table unavailable' "$TMP/out"
: > "$MOUNTS"; : > "$MOUNTINFO"; : > "$SWAPS"
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
