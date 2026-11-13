#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$("$ROOT/rootfs-overlay/usr/bin/vhelp")"
for command in vfetch vdesktop vsettings vnetwork vctl vpm vsoftware vupdate vfiles vinstall vssh vguard vmonitor vhardware vstorage vhealth vlogs vdiagnose vfirewall; do
  grep -q "$command" <<< "$OUT"
done
grep -q 'read-only preflight' <<< "$OUT"
grep -q 'vinstall plan /dev/DISK' <<< "$OUT"
grep -q 'proposed layout' <<< "$OUT"
grep -q 'transactional rollback' <<< "$OUT"
grep -q 'vupdate verify' <<< "$OUT"
grep -q 'vlogs \[--follow\]' <<< "$OUT"
grep -q 'vdiagnose --save' <<< "$OUT"
grep -q 'Live system monitor' "$ROOT/rootfs-overlay/usr/bin/vdesktop"
grep -q "18) Command reference" "$ROOT/rootfs-overlay/usr/bin/vdesktop"
grep -q "alias help='vhelp'" "$ROOT/rootfs-overlay/etc/vampire/shellrc"
echo "Vampire command reference tests passed."
