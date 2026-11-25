#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/run" "$TMP/etc"
cat > "$TMP/passwd" <<'PASSWD'
root:x:0:0:root:/root:/bin/sh
vampire:x:1000:1000:Vampire OS User:/home/vampire:/bin/sh
PASSWD
VAMPIRE_RUN_ROOT="$TMP/run" VAMPIRE_PASSWD_FILE="$TMP/passwd" "$ROOT/rootfs-overlay/usr/lib/vampire/session-runtime"
for uid in 0 1000; do
  dir="$TMP/run/user/$uid"
  [[ -d "$dir" ]]
  [[ "$(stat -c %a "$dir")" == 700 ]]
  [[ "$(stat -c %u "$dir")" == "$uid" ]]
done
echo "Vampire per-user XDG runtime setup tests passed."
