#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/ovmf" "$TMP/logs"
printf "firmware-code" > "$TMP/ovmf/OVMF_CODE_4M.fd"
printf "firmware-vars" > "$TMP/ovmf/OVMF_VARS_4M.fd"
printf "test iso placeholder\n" > "$TMP/live.iso"
cat > "$TMP/bin/qemu-system-x86_64" <<'FAKE'
#!/usr/bin/env bash
set -eu
serial=""
drives=0
while (($#)); do
  case "$1" in
    -serial) serial=$2; shift 2 ;;
    -drive) [[ "$2" == if=pflash,* ]] && { drives=$((drives + 1)); printf "%s\n" "$2" >> "$VAMPIRE_FAKE_DRIVES"; }; shift 2 ;;
    *) shift ;;
  esac
done
[[ "$serial" == file:* ]]
printf 'Vampire OS 0.1.0-dev | x86_64 live environment\nlogin: ' > "${serial#file:}"
printf '%s\n' "$drives" >> "$VAMPIRE_FAKE_DRIVE_COUNTS"
exit 124
FAKE
chmod +x "$TMP/bin/qemu-system-x86_64"
cat > "$TMP/bin/xorriso" <<'FAKE_XORRISO'
#!/usr/bin/env bash
set -eu
extract_path=""
destination=""
while (($#)); do
  if [[ "$1" == "-extract" ]]; then
    extract_path="$2"
    destination="$3"
    break
  fi
  shift
done
[[ -n "$destination" ]]
case "$extract_path" in
  /os-release)
    printf 'NAME="Vampire OS"\nPRETTY_NAME="Vampire OS 0.1.0-dev (%s)"\n' "${VAMPIRE_EDITION:-desktop}" > "$destination"
    ;;
  /boot/initramfs.cpio.gz)
    printf 'fake initramfs payload\n' > "$destination"
    ;;
  *) echo "unexpected xorriso extraction: $extract_path" >&2; exit 1 ;;
esac
FAKE_XORRISO
cat > "$TMP/bin/gzip" <<'FAKE_GZIP'
#!/usr/bin/env bash
set -eu
[[ "$1" == "-dc" ]]
cat "$2"
FAKE_GZIP
cat > "$TMP/bin/cpio" <<'FAKE_CPIO'
#!/usr/bin/env bash
set -eu
[[ "$1" == "-it" ]]
cat >/dev/null
cat <<'LIST'
./usr/bin/vfetch
./usr/bin/vdesktop
./usr/bin/vnetwork
./usr/bin/vinstall
./usr/bin/vpm
./usr/bin/vctl
./etc/vampire/os.conf
./etc/os-release
./usr/bin/weston
./usr/bin/foot
./usr/bin/vampire-terminal
LIST
FAKE_CPIO
chmod +x "$TMP/bin/xorriso" "$TMP/bin/gzip" "$TMP/bin/cpio"
export PATH="$TMP/bin:$PATH"
export VAMPIRE_OVMF_DIR="$TMP/ovmf"
export VAMPIRE_QEMU_LOG_DIR="$TMP/logs"
export VAMPIRE_QEMU_TIMEOUT=3
export VAMPIRE_FAKE_DRIVE_COUNTS="$TMP/drive-counts"
export VAMPIRE_FAKE_DRIVES="$TMP/drives"
bash "$ROOT/scripts/test-live-iso.sh" "$TMP/live.iso"
mapfile -t counts < "$TMP/drive-counts"
[[ "${counts[0]}" == 0 ]]
[[ "${counts[1]}" == 2 ]]
grep -q "readonly=on,file=$TMP/ovmf/OVMF_CODE_4M.fd" "$TMP/drives"
grep -q "file=$TMP/logs/OVMF_VARS." "$TMP/drives"
if compgen -G "$TMP/logs/OVMF_VARS.*.fd" >/dev/null; then echo "temporary OVMF vars image was not cleaned up" >&2; exit 1; fi
echo "UEFI OVMF pflash test passed."
