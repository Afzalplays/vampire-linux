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
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/adb" <<'MOCK_ADB'
#!/usr/bin/env bash
if [[ "$1" == "get-state" ]]; then echo device; exit 0; fi
if [[ "$1" == "shell" && "$2" == "getprop" ]]; then
  case "$3" in
    ro.product.model) echo "Example Phone" ;;
    ro.board.platform) echo "example-soc" ;;
    *) echo "" ;;
  esac
  exit 0
fi
if [[ "$1" == "shell" && "$2" == "cat" ]]; then
  echo "console=ttyAMA0 androidboot.serialno=DO_NOT_LEAK"
  exit 0
fi
if [[ "$1" == "shell" ]]; then
  echo "/dev/block/by-name"
  echo "boot_a -> /dev/block/sda1"
  exit 0
fi
exit 1
MOCK_ADB
cat > "$tmp/fastboot" <<'MOCK_FASTBOOT'
#!/usr/bin/env bash
if [[ "$1" == "devices" ]]; then exit 0; fi
echo "Unexpected fastboot command" >&2
exit 9
MOCK_FASTBOOT
chmod +x "$tmp/adb" "$tmp/fastboot"
PATH="$tmp:$PATH" bash "$script" > "$tmp/report.txt"
grep -q "Example Phone" "$tmp/report.txt"
grep -q "example-soc" "$tmp/report.txt"
grep -q "androidboot.serialno=\\[redacted\\]" "$tmp/report.txt"
grep -q "No device is currently in fastboot mode" "$tmp/report.txt"
if grep -q "DO_NOT_LEAK" "$tmp/report.txt"; then
  echo "Device serial leaked into report." >&2
  exit 1
fi
echo "Mobile device report safety checks passed."
