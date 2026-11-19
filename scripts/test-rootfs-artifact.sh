#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EDITION="${VAMPIRE_EDITION:-desktop}"
ROOTFS_TAR="$ROOT_DIR/out/vampire-os-0.1.0-dev-$EDITION-x86_64-rootfs.tar"
ROOTFS_SUM="$ROOTFS_TAR.sha256"
[[ -s "$ROOTFS_TAR" ]] || { echo "ERROR: installer rootfs archive not found: $ROOTFS_TAR" >&2; exit 1; }
[[ -s "$ROOTFS_SUM" ]] || { echo "ERROR: installer rootfs checksum not found: $ROOTFS_SUM" >&2; exit 1; }
(cd "$(dirname "$ROOTFS_TAR")" && sha256sum -c "$(basename "$ROOTFS_SUM")")
rootfs_listing="$(tar -tf "$ROOTFS_TAR")"
for required in etc/os-release sbin/init bin/busybox boot/vmlinuz usr/lib/vampire/stage-rootfs.py usr/lib/vampire/configure-installed-root.py; do
  grep -Eq "(^|/)${required}$" <<<"$rootfs_listing" || {
    echo "ERROR: installer rootfs is missing required path: $required" >&2
    exit 1
  }
done
if [[ "$EDITION" == desktop ]]; then
  for required in \
    usr/bin/vsettings \
    usr/lib/vampire/settings_apply.py \
    usr/lib/vampire/settings-bootstrap \
    etc/vampire/settings.defaults \
    etc/xdg/weston/weston.ini \
    etc/xdg/foot/foot.ini; do
    grep -Eq "(^|/)${required}$" <<<"$rootfs_listing" || {
      echo "ERROR: Desktop installer rootfs is missing required settings path: $required" >&2
      exit 1
    }
  done
fi
echo "PASS: $EDITION installer rootfs archive and checksum are valid"
