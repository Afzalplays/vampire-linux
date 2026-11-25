#!/bin/sh
# Apply ownership metadata inside Buildroot's fakeroot rootfs finalization.
set -eu
TARGET_DIR=${1:?usage: post-fakeroot-vampire.sh TARGET_DIR}
PASSWD_FILE="$TARGET_DIR/etc/passwd"
SHADOW_FILE="$TARGET_DIR/etc/shadow"
HOME_DIR="$TARGET_DIR/home/vampire"
[ -d "$HOME_DIR" ] || exit 0
[ -r "$PASSWD_FILE" ] || { echo "Vampire OS: passwd database missing during fakeroot finalization" >&2; exit 1; }
account=$(awk -F: '$1 == "vampire" { print $3 ":" $4; count++ } END { if (count != 1) exit 1 }' "$PASSWD_FILE") || {
  echo "Vampire OS: expected exactly one vampire account" >&2
  exit 1
}
case "$account" in *[!0-9:]*|:*|*:) echo "Vampire OS: invalid vampire account IDs" >&2; exit 1 ;; esac
uid=${account%%:*}
gid=${account#*:}
[ "$uid" = 1000 ] || { echo "Vampire OS: refusing unexpected vampire UID $uid" >&2; exit 1; }
chown "$uid:$gid" "$HOME_DIR"
chmod 0755 "$HOME_DIR"
if [ -e "$SHADOW_FILE" ]; then
  chown 0:0 "$SHADOW_FILE"
  chmod 0640 "$SHADOW_FILE"
fi
