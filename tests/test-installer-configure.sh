#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/target"
mkdir -p "$TARGET/boot"
printf kernel > "$TARGET/boot/vmlinuz"
ROOT_UUID=12345678-1234-5678-9abc-123456789abc
ESP_UUID=ABCD-1234
VAMPIRE_INSTALL_CONFIGURER="$ROOT/scripts/configure-installed-root.py" \
  "$ROOT/rootfs-overlay/usr/bin/vinstall" configure "$TARGET" "$ROOT_UUID" uefi "$ESP_UUID"
grep -q "UUID=$ROOT_UUID / ext4" "$TARGET/etc/fstab"
grep -q "UUID=$ESP_UUID /boot/efi vfat" "$TARGET/etc/fstab"
VAMPIRE_INSTALL_CONFIGURER="$ROOT/scripts/configure-installed-root.py" \
  "$ROOT/rootfs-overlay/usr/bin/vinstall" configure "$TARGET" "$ROOT_UUID" bios
! grep -q '/boot/efi' "$TARGET/etc/fstab"
if VAMPIRE_INSTALL_CONFIGURER="$ROOT/scripts/configure-installed-root.py" \
  "$ROOT/rootfs-overlay/usr/bin/vinstall" configure "$TARGET" "$ROOT_UUID" uefi >/dev/null 2>&1; then
  echo "UEFI configure unexpectedly accepted missing ESP UUID" >&2
  exit 1
fi
if VAMPIRE_INSTALL_CONFIGURER="$ROOT/scripts/configure-installed-root.py" \
  "$ROOT/rootfs-overlay/usr/bin/vinstall" configure "$TARGET" "$ROOT_UUID" invalid >/dev/null 2>&1; then
  echo "configure unexpectedly accepted invalid firmware" >&2
  exit 1
fi
echo "vinstall target configuration command tests: PASS"
