#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/id" <<'MOCK'
#!/bin/sh
[ "$1" = -u ] && { echo 0; exit 0; }
exit 1
MOCK
for cmd in reboot poweroff halt sync; do
 cat > "$TMP/bin/$cmd" <<'MOCK'
#!/bin/sh
printf '%s\n' "$(basename "$0")" >> "$VPOWER_CALLS"
MOCK
done
chmod +x "$TMP/bin/"*
export VPOWER_CALLS="$TMP/calls"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vpower" status > "$TMP/status"
grep -q 'Vampire OS power status' "$TMP/status"
if PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vpower" reboot > "$TMP/out" 2>&1; then exit 1; fi
grep -q 'refusing reboot' "$TMP/out"
if PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vpower" poweroff --yes extra >/dev/null 2>&1; then exit 1; fi
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vpower" reboot --yes
printf 'sync\nreboot\n' > "$TMP/expected"
diff -u "$TMP/expected" "$VPOWER_CALLS"
: > "$VPOWER_CALLS"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vpower" poweroff --yes
printf 'sync\npoweroff\n' > "$TMP/expected"
diff -u "$TMP/expected" "$VPOWER_CALLS"

: > "$VPOWER_CALLS"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vpower" halt --yes
printf 'sync\\nhalt\\n' > "$TMP/expected"
diff -u "$TMP/expected" "$VPOWER_CALLS"
# A non-root caller is rejected before sync or the power command runs.
cat > "$TMP/bin/id" <<'MOCK'
#!/bin/sh
[ "$1" = -u ] && { echo 1000; exit 0; }
exit 1
MOCK
: > "$VPOWER_CALLS"
if PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vpower" reboot --yes > "$TMP/out" 2>&1; then
  echo "non-root reboot unexpectedly succeeded" >&2; exit 1
fi
grep -q 'requires root' "$TMP/out"
test ! -s "$VPOWER_CALLS"
if PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vpower" status extra >/dev/null 2>&1; then
  echo "status accepted unexpected arguments" >&2; exit 1
fi
echo 'Vampire power-control tests passed.'
