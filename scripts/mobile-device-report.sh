#!/usr/bin/env bash
# Read-only Android reference-device inventory for a future Vampire Mobile port.
set -Eeuo pipefail
command -v adb >/dev/null 2>&1 || { echo "adb is required (Android platform-tools)." >&2; exit 1; }
if ! adb get-state >/dev/null 2>&1; then
  echo "No authorized Android device found. Enable USB debugging and accept the device prompt." >&2
  exit 2
fi
getprop_value() {
  key=$1
  value=$(adb shell getprop "$key" 2>/dev/null | tr -d '\r' || true)
  [ -n "$value" ] || value="(not reported)"
  printf '| %s | %s |\n' "$key" "$value"
}
printf '# Android reference-device report (read-only)\n\n'
printf '| Property | Value |\n|---|---|\n'
for key in ro.product.manufacturer ro.product.model ro.product.device ro.product.name ro.board.platform ro.hardware ro.boot.hardware ro.bootloader ro.build.version.release ro.build.version.sdk ro.boot.slot_suffix ro.boot.verifiedbootstate ro.boot.flash.locked; do
  getprop_value "$key"
done
printf '\n## Boot and partition information\n\n'
printf '### Kernel command line\n\n'
adb shell cat /proc/cmdline 2>/dev/null | tr -d '\r' | sed -E 's/(androidboot\.(serialno|serial|imei)=)[^ ]+/\1[redacted]/g' || true
printf '\n\n### Named partitions\n\n'
adb shell 'for p in /dev/block/by-name /dev/block/bootdevice/by-name; do if [ -d "$p" ]; then echo "$p"; ls -l "$p"; fi; done' 2>/dev/null | tr -d '\r' || true
printf '\n\n## Fastboot availability\n\n'
if command -v fastboot >/dev/null 2>&1; then
  if fastboot devices 2>/dev/null | grep -q .; then
    fastboot getvar product 2>&1 || true
    fastboot getvar unlocked 2>&1 || true
    fastboot getvar current-slot 2>&1 || true
  else
    echo 'No device is currently in fastboot mode; ADB properties were collected.'
  fi
else
  echo 'fastboot is not installed on this host.'
fi
printf '\nThis report does not unlock, reboot, erase, flash, or modify the device. Review and redact anything you do not want to share before sending it.\n'
