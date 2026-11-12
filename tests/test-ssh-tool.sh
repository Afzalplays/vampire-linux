#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
sh -n "$ROOT/rootfs-overlay/usr/bin/vssh"
grep -qi 'password authentication is disabled' "$ROOT/rootfs-overlay/usr/bin/vssh"
grep -q '/var/lib/vampire/ssh/dropbear_ed25519_host_key' "$ROOT/rootfs-overlay/usr/bin/vssh"
grep -q 'Refusing to start' "$ROOT/rootfs-overlay/usr/bin/vssh"
grep -q 'BR2_PACKAGE_DROPBEAR=y' "$ROOT/build/vampire_defconfig"
echo "Vampire SSH tool contract tests passed."
