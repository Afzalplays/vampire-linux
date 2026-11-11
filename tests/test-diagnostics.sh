#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
for t in vhardware vstorage vhealth vlogs vdiagnose vfirewall; do sh -n "$ROOT/rootfs-overlay/usr/bin/$t"; done
sh -n "$ROOT/rootfs-overlay/etc/vampire/services.d/firewall"
grep -qi 'read-only' "$ROOT/rootfs-overlay/usr/bin/vstorage"
grep -q 'No diagnostic command uploads data' "$ROOT/docs/HARDWARE-DIAGNOSTICS.md"
grep -qx network "$ROOT/rootfs-overlay/etc/vampire/services.enabled"
! grep -qx firewall "$ROOT/rootfs-overlay/etc/vampire/services.enabled"
echo 'Vampire diagnostics tests passed.'
