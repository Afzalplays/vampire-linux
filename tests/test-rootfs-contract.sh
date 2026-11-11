#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for file in rootfs-overlay/usr/bin/vctl rootfs-overlay/usr/bin/vnetwork rootfs-overlay/usr/bin/vguard rootfs-overlay/usr/bin/vsettings rootfs-overlay/usr/bin/vdesktop rootfs-overlay/etc/vampire/settings.defaults rootfs-overlay/etc/vampire/services.d/network rootfs-overlay/etc/profile.d/vampire.sh; do
  test -s "$ROOT/$file"
done
bash -n "$ROOT/rootfs-overlay/usr/bin/vctl"
bash -n "$ROOT/rootfs-overlay/usr/bin/vnetwork"
bash -n "$ROOT/rootfs-overlay/usr/bin/vguard"
sh -n "$ROOT/rootfs-overlay/usr/bin/vsettings"
sh -n "$ROOT/rootfs-overlay/usr/bin/vdesktop"
sh -n "$ROOT/rootfs-overlay/etc/init.d/rcS"
sh -n "$ROOT/rootfs-overlay/etc/vampire/services.d/network"
grep -q 'BusyBox init' "$ROOT/rootfs-overlay/etc/vampire/os.conf"
grep -q 'production supervisor' "$ROOT/docs/VAMPIRE-INIT.md"
grep -q '/usr/bin/vctl start network' "$ROOT/rootfs-overlay/etc/init.d/rcS"
grep -q 'VAMPIRE_SSH_PORT' "$ROOT/rootfs-overlay/usr/bin/vguard"
grep -q 'udhcpc -n -q -i' "$ROOT/rootfs-overlay/usr/bin/vnetwork"
grep -q 'settings.conf' "$ROOT/rootfs-overlay/etc/init.d/rcS"
echo "Vampire rootfs contract checks passed."
