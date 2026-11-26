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

# A symlinked per-user runtime directory must be rejected before chown/chmod.
mkdir -p "$TMP/outside"
rm -rf "$TMP/run/user/1000"
ln -s "$TMP/outside" "$TMP/run/user/1000"
if CHOWN_LOG="$TMP/attack.log" PATH="$TMP/bin:$PATH" VAMPIRE_RUN_ROOT="$TMP/run" VAMPIRE_PASSWD_FILE="$TMP/passwd" sh "$ROOT/rootfs-overlay/usr/lib/vampire/session-runtime" >/dev/null 2>&1; then
  echo "session runtime accepted a symlinked user directory" >&2; exit 1
fi
[[ ! -s "$TMP/attack.log" ]] || { echo "session runtime attempted chown through a symlink" >&2; exit 1; }

# A symlinked runtime root must also be refused.
rm -rf "$TMP/run/user"
ln -s "$TMP/outside" "$TMP/run/user"
if CHOWN_LOG="$TMP/attack-root.log" PATH="$TMP/bin:$PATH" VAMPIRE_RUN_ROOT="$TMP/run" VAMPIRE_PASSWD_FILE="$TMP/passwd" sh "$ROOT/rootfs-overlay/usr/lib/vampire/session-runtime" >/dev/null 2>&1; then
  echo "session runtime accepted a symlinked user root" >&2; exit 1
fi
[[ ! -s "$TMP/attack-root.log" ]] || { echo "session runtime attempted chown through a symlinked root" >&2; exit 1; }

echo "Vampire per-user XDG runtime setup tests passed."
