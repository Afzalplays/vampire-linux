#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/ovmf" "$TMP/logs"
: > "$TMP/ovmf/OVMF_CODE_4M.fd"
: > "$TMP/ovmf/OVMF_VARS_4M.fd"
: > "$TMP/live.iso"
cat > "$TMP/bin/qemu-system-x86_64" <<'FAKE'
#!/usr/bin/env bash
set -eu
serial=""
drives=0
while (($#)); do
  case "$1" in
    -serial) serial=$2; shift 2 ;;
    -drive) [[ "$2" == if=pflash,* ]] && drives=$((drives + 1)); shift 2 ;;
    *) shift ;;
  esac
done
[[ "$serial" == file:* ]]
printf 'Vampire OS 0.1.0-dev | x86_64 live environment\nlogin: ' > "${serial#file:}"
printf '%s\n' "$drives" >> "$VAMPIRE_FAKE_DRIVE_COUNTS"
exit 124
FAKE
chmod +x "$TMP/bin/qemu-system-x86_64"
export PATH="$TMP/bin:$PATH"
export VAMPIRE_OVMF_DIR="$TMP/ovmf"
export VAMPIRE_QEMU_LOG_DIR="$TMP/logs"
export VAMPIRE_QEMU_TIMEOUT=3
export VAMPIRE_FAKE_DRIVE_COUNTS="$TMP/drive-counts"
bash "$ROOT/scripts/test-live-iso.sh" "$TMP/live.iso"
mapfile -t counts < "$TMP/drive-counts"
[[ "${counts[0]}" == 0 ]]
[[ "${counts[1]}" == 2 ]]
grep -q 'readonly=on' "$TMP/logs/uefi.qemu.stderr" && { echo "unexpected QEMU stderr content" >&2; exit 1; } || true
[[ ! -e "$TMP/logs/OVMF_VARS.XXXXXX.fd" ]]
echo "UEFI OVMF pflash test passed."
