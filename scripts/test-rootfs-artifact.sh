#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EDITION="${VAMPIRE_EDITION:-desktop}"
case "$EDITION" in desktop|server) ;; *) echo "ERROR: unsupported edition: $EDITION" >&2; exit 2 ;; esac
ROOTFS_TAR="$ROOT_DIR/out/vampire-os-0.1.0-dev-$EDITION-x86_64-rootfs.tar"
ROOTFS_SUM="$ROOTFS_TAR.sha256"
[[ -s "$ROOTFS_TAR" ]] || { echo "ERROR: installer rootfs archive not found: $ROOTFS_TAR" >&2; exit 1; }
[[ -s "$ROOTFS_SUM" ]] || { echo "ERROR: installer rootfs checksum not found: $ROOTFS_SUM" >&2; exit 1; }
(cd "$(dirname "$ROOTFS_TAR")" && sha256sum -c "$(basename "$ROOTFS_SUM")")
rootfs_listing="$(tar -tf "$ROOTFS_TAR")"
for required in etc/os-release sbin/init bin/busybox boot/vmlinuz usr/lib/vampire/stage-rootfs.py usr/lib/vampire/configure-installed-root.py usr/lib/vampire/session-runtime etc/passwd etc/group etc/shadow; do
  grep -Eq "(^|/)\${required}$" <<<"$rootfs_listing" || {
    echo "ERROR: installer rootfs is missing required path: $required" >&2
    exit 1
  }
done
member_path() {
  local suffix=$1
  grep -E "(^|/)\${suffix}$" <<<"$rootfs_listing" | head -n 1 || true
}
passwd_member="$(member_path etc/passwd)"
group_member="$(member_path etc/group)"
shadow_member="$(member_path etc/shadow)"
grep -Eq '^vampire:x:1000:[0-9]+:Vampire OS User:/home/vampire:/bin/sh$' <(tar -xOf "$ROOTFS_TAR" "$passwd_member") || {
  echo "ERROR: rootfs does not contain the unprivileged Vampire account" >&2
  exit 1
}
grep -Eq '^vampire:!:.*$' <(tar -xOf "$ROOTFS_TAR" "$shadow_member") || {
  echo "ERROR: Vampire account is not locked by default" >&2
  exit 1
}
for group_name in video input; do
  awk -F: -v wanted="$group_name" '$1 == wanted { count=split($4, members, ","); for (i=1; i<=count; i++) if (members[i] == "vampire") found=1 } END { exit !found }' <(tar -xOf "$ROOTFS_TAR" "$group_member") || {
    echo "ERROR: Vampire account is not in the $group_name group" >&2
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
    etc/xdg/foot/foot.ini \
    usr/bin/vdesktop \
    usr/bin/vgraphical \
    usr/bin/vampire-app \
    usr/bin/vampire-terminal; do
    grep -Eq "(^|/)\${required}$" <<<"$rootfs_listing" || {
      echo "ERROR: Desktop installer rootfs is missing required Desktop runtime path: $required" >&2
      exit 1
    }
  done
fi
echo "PASS: $EDITION installer rootfs archive, account and runtime payload are valid"
