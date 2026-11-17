#!/usr/bin/env bash
set -Eeuo pipefail
set -x
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
grep -qx 'BR2_PACKAGE_WESTON=y' "$ROOT/build/vampire_defconfig"
grep -qx 'BR2_PACKAGE_DROPBEAR=y' "$ROOT/build/vampire_server_defconfig"
! grep -q 'BR2_PACKAGE_WESTON=y' "$ROOT/build/vampire_server_defconfig"
grep -q 'VAMPIRE_EDITION' "$ROOT/build/build-live-iso.sh"
grep -q 'server-x86_64.iso' "$ROOT/.github/workflows/server-iso.yml"
grep -q 'vpm/\*\*' "$ROOT/.github/workflows/live-iso.yml"
grep -q 'fetch/vfetch' "$ROOT/.github/workflows/server-iso.yml"
# Installed boot must use built-in storage drivers because it intentionally has no initramfs.
for option in CONFIG_EXT4_FS CONFIG_SCSI CONFIG_BLK_DEV_SD CONFIG_SATA_AHCI CONFIG_BLK_DEV_NVME CONFIG_VIRTIO_BLK CONFIG_EFI_PARTITION; do
  grep -qx "$option=y" "$ROOT/build/vampire-installer-kernel.fragment"
done
grep -q 'root=UUID=' "$ROOT/scripts/configure-installed-root.py"
! grep -q 'initrd ' "$ROOT/scripts/configure-installed-root.py"
echo "Vampire Desktop/Server edition configuration tests passed."
