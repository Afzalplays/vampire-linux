#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
sh -n "$ROOT/rootfs-overlay/usr/bin/vfiles"
export VFILES_START_DIR="$TMP"
printf 'mkdir\ncreated-dir\n\nquit\n' | sh "$ROOT/rootfs-overlay/usr/bin/vfiles" >/dev/null
test -d "$TMP/created-dir"
printf 'touch\ncreated-file\n\nquit\n' | sh "$ROOT/rootfs-overlay/usr/bin/vfiles" >/dev/null
test -f "$TMP/created-file"
printf 'keep this content\n' > "$TMP/created-file"
printf 'touch\ncreated-file\n\nquit\n' | sh "$ROOT/rootfs-overlay/usr/bin/vfiles" >/dev/null
grep -qx 'keep this content' "$TMP/created-file"
printf 'copy-source\n' > "$TMP/source"
printf 'copy\nsource\ncopied\n\nquit\n' | sh "$ROOT/rootfs-overlay/usr/bin/vfiles" >/dev/null
grep -qx 'copy-source' "$TMP/copied"
printf 'old-content\n' > "$TMP/copied"
printf 'copy\nsource\ncopied\nn\n\nquit\n' | sh "$ROOT/rootfs-overlay/usr/bin/vfiles" >/dev/null
grep -qx 'old-content' "$TMP/copied"
printf 'copy\nsource\ncopied\ny\n\nquit\n' | sh "$ROOT/rootfs-overlay/usr/bin/vfiles" >/dev/null
grep -qx 'copy-source' "$TMP/copied"
printf 'delete\ncreated-file\nn\n\nquit\n' | sh "$ROOT/rootfs-overlay/usr/bin/vfiles" >/dev/null
test -f "$TMP/created-file"
printf 'delete\ncreated-file\ny\n\nquit\n' | sh "$ROOT/rootfs-overlay/usr/bin/vfiles" >/dev/null
test ! -e "$TMP/created-file"
echo "Vampire Files console tests passed."
