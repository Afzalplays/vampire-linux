#!/usr/bin/env bash
set -Eeuo pipefail
script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/scripts/mobile-device-report.sh"
bash -n "$script"
grep -q 'adb get-state' "$script"
grep -q 'ro.board.platform' "$script"
grep -q 'serialno.*redacted' "$script"
grep -q 'fastboot devices' "$script"
grep -q '/dev/block/by-name' "$script"
if grep -Eiq 'fastboot (flash|erase|unlock)|adb reboot|adb sideload' "$script"; then
  echo "Device report must remain read-only." >&2
  exit 1
fi
echo "Mobile device report safety checks passed."
