#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/target/etc" "$TMP/target/home/vampire" "$TMP/bin"
cat > "$TMP/target/etc/passwd" <<'PASSWD'
root:x:0:0:root:/root:/bin/sh
vampire:x:1000:1000:Vampire OS User:/home/vampire:/bin/sh
PASSWD
: > "$TMP/target/etc/shadow"
cat > "$TMP/bin/chown" <<'MOCK'
#!/bin/sh
printf '%s\n' "$*" >> "$CHOWN_LOG"
MOCK
chmod +x "$TMP/bin/chown"
CHOWN_LOG="$TMP/chown.log" PATH="$TMP/bin:$PATH" sh "$ROOT/scripts/post-fakeroot-vampire.sh" "$TMP/target"
grep -qx '1000:1000 '"$TMP/target/home/vampire" "$TMP/chown.log"
grep -qx '0:0 '"$TMP/target/etc/shadow" "$TMP/chown.log"
[[ "$(stat -c %a "$TMP/target/home/vampire")" == 755 ]]
[[ "$(stat -c %a "$TMP/target/etc/shadow")" == 640 ]]
sed -i 's/vampire:x:1000:/vampire:x:1001:/' "$TMP/target/etc/passwd"
if CHOWN_LOG="$TMP/invalid.log" PATH="$TMP/bin:$PATH" sh "$ROOT/scripts/post-fakeroot-vampire.sh" "$TMP/target" >/dev/null 2>&1; then
  echo "fakeroot finalizer accepted an unexpected Vampire UID" >&2
  exit 1
fi
echo "Vampire fakeroot ownership tests passed."
