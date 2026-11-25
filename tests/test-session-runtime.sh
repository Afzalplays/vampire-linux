#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/run" "$TMP/etc" "$TMP/bin"
cat > "$TMP/bin/chown" <<'MOCK'
#!/bin/sh
printf '%s %s\n' "$1" "$2" >> "$CHOWN_LOG"
MOCK
chmod +x "$TMP/bin/chown"
cat > "$TMP/passwd" <<'PASSWD'
root:x:0:0:root:/root:/bin/sh
vampire:x:1000:1000:Vampire OS User:/home/vampire:/bin/sh
PASSWD
CHOWN_LOG="$TMP/chown.log" PATH="$TMP/bin:$PATH" VAMPIRE_RUN_ROOT="$TMP/run" VAMPIRE_PASSWD_FILE="$TMP/passwd" sh "$ROOT/rootfs-overlay/usr/lib/vampire/session-runtime"
for uid in 0 1000; do
  dir="$TMP/run/user/$uid"
  [[ -d "$dir" ]]
  [[ "$(stat -c %a "$dir")" == 700 ]]
done
grep -Fq "0:0 $TMP/run/user/0" "$TMP/chown.log"
grep -Fq "1000:1000 $TMP/run/user/1000" "$TMP/chown.log"
echo "Vampire per-user XDG runtime setup tests passed."
