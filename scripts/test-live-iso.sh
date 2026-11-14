#!/usr/bin/env bash
# Boot the built ISO in legacy BIOS and UEFI firmware and verify the live init.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EDITION="${VAMPIRE_EDITION:-desktop}"
ISO="${1:-$ROOT_DIR/out/vampire-os-0.1.0-dev-$EDITION-x86_64.iso}"
LOG_DIR="${VAMPIRE_QEMU_LOG_DIR:-$ROOT_DIR/out/qemu-logs}"
TIMEOUT_SECONDS="${VAMPIRE_QEMU_TIMEOUT:-75}"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing test tool: $1"; }
need qemu-system-x86_64
need xorriso
need timeout
need gzip
need cpio
[[ -s "$ISO" ]] || die "ISO not found: $ISO"
mkdir -p "$LOG_DIR"

# Verify the release metadata embedded at ISO root matches this build target.
metadata_file="$(mktemp "$LOG_DIR/os-release.XXXXXX")"
if ! xorriso -osirrox on -indev "$ISO" -extract /os-release "$metadata_file" >/dev/null 2>&1; then
  rm -f "$metadata_file"
  die "could not read /os-release from ISO"
fi
expected_pretty_name='PRETTY_NAME="Vampire OS 0.1.0-dev ('"$EDITION"')"';
if ! grep -Fqx "$expected_pretty_name" "$metadata_file"; then
  cat "$metadata_file" >&2
  rm -f "$metadata_file"
  die "ISO release metadata does not match requested edition: $EDITION"
fi
rm -f "$metadata_file"

# Verify the installer payload is physically embedded in the bootable ISO.
install_tmp="$(mktemp -d "$LOG_DIR/installer-payload.XXXXXX")"
trap 'rm -rf "$install_tmp"' EXIT
xorriso -osirrox on -indev "$ISO" -extract /install/rootfs.tar "$install_tmp/rootfs.tar" >/dev/null 2>&1 \
  || die "could not extract installer rootfs from ISO"
xorriso -osirrox on -indev "$ISO" -extract /install/rootfs.tar.sha256 "$install_tmp/rootfs.tar.sha256" >/dev/null 2>&1 \
  || die "could not extract installer rootfs checksum from ISO"
(cd "$install_tmp" && sha256sum -c rootfs.tar.sha256) || die "embedded installer rootfs checksum failed"
embedded_listing="$(tar -tf "$install_tmp/rootfs.tar")"
for required in etc/os-release sbin/init bin/busybox boot/vmlinuz usr/lib/vampire/stage-rootfs.py; do
  grep -Eq "(^|/)\${required}$" <<<"$embedded_listing" || die "embedded rootfs is missing required path: $required"
done
printf 'PASS: %s ISO contains a checksummed installer rootfs and kernel\\n' "$EDITION"
rm -rf "$install_tmp"
trap - EXIT

# Inspect the actual initramfs payload, not only the ISO's outer metadata.
initramfs_file="$(mktemp "$LOG_DIR/initramfs.XXXXXX.gz")"
xorriso -osirrox on -indev "$ISO" -extract /boot/initramfs.cpio.gz "$initramfs_file" >/dev/null 2>&1 \
  || die "could not extract the ISO initramfs"
initramfs_listing="$(gzip -dc "$initramfs_file" | cpio -it 2>/dev/null)" \
  || die "could not list the ISO initramfs"
rm -f "$initramfs_file"
has_entry() {
  grep -Eq "(^|/)$1$" <<<"$initramfs_listing" || die "initramfs is missing required file: $1"
}
for required in \
  usr/bin/vfetch usr/bin/vdesktop usr/bin/vnetwork usr/bin/vinstall \
  usr/bin/vpm usr/bin/vctl etc/vampire/os.conf etc/os-release; do
  has_entry "$required"
done
if [[ "$EDITION" == "desktop" ]]; then
  has_entry usr/bin/weston
  has_entry usr/bin/foot
  has_entry usr/bin/vampire-terminal
else
  if grep -Eq "(/|^)usr/bin/weston$" <<<"$initramfs_listing"; then
    die "Server initramfs unexpectedly includes the Weston desktop"
  fi
fi
printf "PASS: %s initramfs contains the expected Vampire OS runtime\n" "$EDITION"

run_boot() {
  local mode="$1"
  local log="$LOG_DIR/$mode.log"
  local stderr_log="$LOG_DIR/$mode.qemu.stderr"
  local vars_copy=""
  local -a firmware=()
  if [[ "$mode" == "uefi" ]]; then
    # OVMF needs a matched CODE/VARS pflash pair; never modify host NVRAM.
    local ovmf_dir="" code_name vars_name ovmf_code="" ovmf_vars="" candidate
    local -a ovmf_dirs=()
    if [[ -n "${VAMPIRE_OVMF_DIR:-}" ]]; then
      ovmf_dirs=("$VAMPIRE_OVMF_DIR")
    else
      ovmf_dirs=(/usr/share/OVMF /usr/share/ovmf)
    fi
    for candidate in "${ovmf_dirs[@]}"; do
      [[ -d "$candidate" ]] && { ovmf_dir="$candidate"; break; }
    done
    [[ -n "$ovmf_dir" ]] || die "UEFI firmware directory not found"
    for code_name in OVMF_CODE_4M.fd OVMF_CODE.fd; do
      case "$code_name" in
        *_4M.fd) vars_name=OVMF_VARS_4M.fd ;;
        *) vars_name=OVMF_VARS.fd ;;
      esac
      if [[ -s "$ovmf_dir/$code_name" && -s "$ovmf_dir/$vars_name" ]]; then
        ovmf_code="$ovmf_dir/$code_name"
        ovmf_vars="$ovmf_dir/$vars_name"
        break
      fi
    done
    [[ -n "$ovmf_code" && -n "$ovmf_vars" ]] || die "Matching OVMF_CODE and OVMF_VARS firmware pair not found"
    vars_copy="$(mktemp "$LOG_DIR/OVMF_VARS.XXXXXX.fd")"
    cp "$ovmf_vars" "$vars_copy"
    firmware=(
      -drive "if=pflash,format=raw,unit=0,readonly=on,file=$ovmf_code"
      -drive "if=pflash,format=raw,unit=1,file=$vars_copy"
    )
  fi

  rm -f "$log" "$stderr_log"
  set +e
  timeout --signal=TERM "$TIMEOUT_SECONDS" qemu-system-x86_64 \
    -machine accel=tcg -m 1024 -smp 2 -cdrom "$ISO" -boot d \
    -display none -monitor none -serial "file:$log" -no-reboot \
    "${firmware[@]}" >/dev/null 2>"$stderr_log"
  local status=$?
  set -e
  [[ -z "$vars_copy" ]] || rm -f "$vars_copy"

  if [[ "$status" -ne 124 && "$status" -ne 143 ]]; then
    printf '%s\n' "---- $mode QEMU stderr ----" >&2
    cat "$stderr_log" >&2 || true
    printf '%s\n' "---- $mode boot log ----" >&2
    cat "$log" >&2 || true
    die "$mode QEMU exited unexpectedly (status $status)"
  fi

  grep -Fq 'Vampire OS 0.1.0-dev | x86_64 live environment' "$log" || {
    printf '%s\n' "---- $mode boot log ----" >&2
    cat "$log" >&2 || true
    die "$mode boot did not reach Vampire live init"
  }
  grep -Eqi 'login:|Password:' "$log" || die "$mode boot did not reach the serial login prompt"
  printf 'PASS: %s boot reached Vampire OS init and serial login\n' "$mode"
}

run_boot bios
run_boot uefi
printf 'QEMU boot smoke tests passed. Logs: %s\n' "$LOG_DIR"
