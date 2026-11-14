#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
mkdir -p "$TMP/bin"
printf "#!/bin/sh\\necho 0\\n" > "$TMP/bin/id"
chmod +x "$TMP/bin/id"
export PATH="$TMP/bin:$PATH"
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
printf '#!/bin/sh\\necho 1000\\n' > "$TMP/bin/id"
chmod +x "$TMP/bin/id"
if "$ROOT/rootfs-overlay/usr/bin/vinstall" configure "$TARGET" "$ROOT_UUID" bios >/dev/null 2>&1; then
  echo "installer unexpectedly allowed non-root operation" >&2
  exit 1
fi
printf '#!/bin/sh\\necho 0\\n' > "$TMP/bin/id"
chmod +x "$TMP/bin/id"
echo "vinstall target configuration command tests: PASS"
