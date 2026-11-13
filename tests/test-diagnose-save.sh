#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/support"
for tool in vhealth vhardware vmonitor vstorage vnetwork vguard; do
  cat > "$TMP/bin/$tool" <<MOCK
#!/bin/sh
printf '%s\\n' '$tool diagnostic output'
MOCK
  chmod +x "$TMP/bin/$tool"
done
cat > "$TMP/bin/vlogs" <<'MOCK'
#!/bin/sh
echo 'test log line'
MOCK
chmod +x "$TMP/bin/vlogs"
output=$(PATH="$TMP/bin:/usr/bin:/bin" sh "$ROOT/rootfs-overlay/usr/bin/vdiagnose" --save "$TMP/support")
grep -q 'Support snapshot saved with mode 600' <<< "$output"
files=("$TMP"/support/vampire-support-*.txt)
test "${#files[@]}" -eq 1
test "$(stat -c '%a' "$TMP/support")" = 700
test "$(stat -c '%a' "${files[0]}")" = 600
grep -q 'VAMPIRE SUPPORT SNAPSHOT' "${files[0]}"
grep -q 'vhardware diagnostic output' "${files[0]}"
grep -q 'test log line' "${files[0]}"
grep -q 'Review before sharing' "${files[0]}"
if sh "$ROOT/rootfs-overlay/usr/bin/vdiagnose" --save "$TMP/support" extra >/dev/null 2>&1; then
  echo 'vdiagnose accepted extra arguments' >&2; exit 1
fi
echo 'Vampire support snapshot export tests passed.'
