#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/dev" "$TMP/sys/block/vda/holders"
: > "$TMP/dev/vda"
printf '41943040\n' > "$TMP/sys/block/vda/size"
printf '0\n' > "$TMP/sys/block/vda/ro"
printf '0\n' > "$TMP/sys/block/vda/removable"
printf '252:0\n' > "$TMP/sys/block/vda/dev"
: > "$TMP/mounts"
: > "$TMP/mountinfo"
printf 'Filename Type Size Used Priority\n' > "$TMP/swaps"

cat > "$TMP/bin/id" <<'EOF'
#!/bin/sh
[ "${1:-}" = -u ] && { echo 0; exit 0; }
exit 1
EOF
chmod 0755 "$TMP/bin/id"
for tool in parted partprobe udevadm mkfs.fat mkfs.ext4 mount umount grub-install blkid; do
  cat > "$TMP/bin/$tool" <<EOF
#!/bin/sh
EOF
  if [ "$tool" = parted ]; then
    printf 'printf called > "%s"\n' "$TMP/parted-called" >> "$TMP/bin/$tool"
  else
    printf 'exit 0\n' >> "$TMP/bin/$tool"
  fi
  chmod 0755 "$TMP/bin/$tool"
done

mkdir -p "$TMP/rootfs/etc" "$TMP/rootfs/sbin" "$TMP/rootfs/bin"
printf 'NAME="Vampire OS"\n' > "$TMP/rootfs/etc/os-release"
printf '#!/bin/sh\n' > "$TMP/rootfs/sbin/init"
printf 'busybox fixture\n' > "$TMP/rootfs/bin/busybox"
tar -cf "$TMP/rootfs.tar" -C "$TMP/rootfs" .
(cd "$TMP" && sha256sum rootfs.tar > rootfs.tar.sha256)
printf 'kernel fixture\n' > "$TMP/vmlinuz"
printf 'initramfs fixture\n' > "$TMP/initramfs.cpio.gz"

export PATH="$TMP/bin:$PATH"
export VAMPIRE_SYS_BLOCK="$TMP/sys/block"
export VAMPIRE_DEV_ROOT="$TMP/dev"
export VAMPIRE_MOUNTS_FILE="$TMP/mounts"
export VAMPIRE_MOUNTINFO_FILE="$TMP/mountinfo"
export VAMPIRE_SWAPS_FILE="$TMP/swaps"
export VAMPIRE_ROOTFS_STAGE="$ROOT/scripts/stage-rootfs.py"
export VAMPIRE_INSTALL_CONFIGURER="$ROOT/scripts/configure-installed-root.py"
export VAMPIRE_KERNEL_IMAGE="$TMP/vmlinuz"
export VAMPIRE_INITRAMFS_IMAGE="$TMP/initramfs.cpio.gz"

if printf 'NO\n' | "$ROOT/rootfs-overlay/usr/bin/vinstall" install "$TMP/rootfs.tar" "$TMP/dev/vda" bios > "$TMP/output" 2>&1; then
  echo 'installer accepted an incorrect destructive confirmation' >&2
  exit 1
fi
grep -q 'Installation cancelled; disk was not changed' "$TMP/output"
[ ! -e "$TMP/parted-called" ]
echo 'installer destructive-confirmation test: PASS'
