#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
grep -qx 'BR2_PACKAGE_WESTON=y' "$ROOT/build/vampire_defconfig"
grep -qx 'BR2_PACKAGE_DROPBEAR=y' "$ROOT/build/vampire_server_defconfig"
! grep -q 'BR2_PACKAGE_WESTON=y' "$ROOT/build/vampire_server_defconfig"
grep -q 'VAMPIRE_EDITION' "$ROOT/build/build-live-iso.sh"
grep -q 'server-x86_64.iso' "$ROOT/.github/workflows/server-iso.yml"
grep -q 'vpm/\*\*' "$ROOT/.github/workflows/live-iso.yml"
grep -q 'fetch/vfetch' "$ROOT/.github/workflows/server-iso.yml"
echo "Vampire Desktop/Server edition configuration tests passed."
