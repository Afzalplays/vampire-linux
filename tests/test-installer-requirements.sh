#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
mkdir -p "$TMP/bin"
for tool in sfdisk parted partprobe udevadm mkfs.fat mkfs.ext4 mount umount grub-install blkid tar python3 sha256sum; do
  printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/$tool"
  chmod 0755 "$TMP/bin/$tool"
done
PATH="$TMP/bin" "$ROOT/rootfs-overlay/usr/bin/vinstall" requirements > "$TMP/ok"
grep -q 'All disk-installation prerequisites are present' "$TMP/ok"
rm "$TMP/bin/partprobe"
if PATH="$TMP/bin" "$ROOT/rootfs-overlay/usr/bin/vinstall" requirements > "$TMP/missing"; then
  echo 'requirements unexpectedly passed without grub-install' >&2
  exit 1
fi
grep -q 'MISSING    partprobe' "$TMP/missing"
grep -q 'Installer execution is unavailable' "$TMP/missing"
echo 'installer requirements tests: PASS'
