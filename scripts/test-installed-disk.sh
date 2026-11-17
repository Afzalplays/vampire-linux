#!/usr/bin/env bash
# Create disposable BIOS/UEFI disk images, install the staged rootfs and boot them in QEMU.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EDITION="${VAMPIRE_EDITION:-desktop}"
ROOTFS_TAR="$ROOT_DIR/out/vampire-os-0.1.0-dev-$EDITION-x86_64-rootfs.tar"
WORK="${VAMPIRE_INSTALL_TEST_DIR:-$ROOT_DIR/out/installed-disk-tests}"
TIMEOUT_SECONDS="${VAMPIRE_INSTALLED_BOOT_TIMEOUT:-60}"
LOOPS=()
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing test tool: $1"; }
for tool in sudo losetup parted partprobe udevadm mkfs.ext4 mkfs.fat mount umount blkid grub-install qemu-system-x86_64 timeout tar sha256sum python3 truncate cp rm grep; do need "$tool"; done
[[ -s "$ROOTFS_TAR" ]] || die "Missing rootfs archive: $ROOTFS_TAR"
[[ -s "$ROOTFS_TAR.sha256" ]] || die "Missing rootfs checksum: $ROOTFS_TAR.sha256"
mkdir -p "$WORK"
VAMPIRE_ROOTFS_STAGE="$ROOT_DIR/scripts/stage-rootfs.py" "$ROOT_DIR/rootfs-overlay/usr/bin/vinstall" validate "$ROOTFS_TAR"
cleanup() {
  set +e
  for loop in "${LOOPS[@]}"; do sudo losetup -d "$loop" >/dev/null 2>&1 || true; done
  rm -f "$WORK"/OVMF_VARS.*.fd
}
trap cleanup EXIT HUP INT TERM

find_ovmf() {
  local dir candidate code vars
  for dir in /usr/share/OVMF /usr/share/ovmf; do
    [[ -d "$dir" ]] || continue
    for candidate in OVMF_CODE_4M.fd OVMF_CODE.fd; do
      if [[ "$candidate" == *_4M.fd ]]; then vars=OVMF_VARS_4M.fd; else vars=OVMF_VARS.fd; fi
      if [[ -s "$dir/$candidate" && -s "$dir/$vars" ]]; then
        printf '%s|%s\n' "$dir/$candidate" "$dir/$vars"
        return 0
      fi
    done
  done
  return 1
}

run_boot() {
  local mode="$1" image loop
  image="$WORK/$mode.img"
  local log="$WORK/$mode.serial.log" stderr="$WORK/$mode.qemu.stderr" status
  truncate -s 8G "$image"
  loop="$(sudo losetup --find --show --partscan "$image")"
  LOOPS+=("$loop")

  # Exercise the exact installer command used by the live ISO, not a parallel
  # test-only partitioning implementation.
  printf 'ERASE %s\n' "$loop" | sudo env \
    VAMPIRE_ROOTFS_STAGE="$ROOT_DIR/scripts/stage-rootfs.py" \
    VAMPIRE_INSTALL_CONFIGURER="$ROOT_DIR/scripts/configure-installed-root.py" \
    VAMPIRE_KERNEL_IMAGE="$ROOT_DIR/.build/output-$EDITION/images/bzImage" \
    "$ROOT_DIR/rootfs-overlay/usr/bin/vinstall" install "$ROOTFS_TAR" "$loop" "$mode"

  rm -f "$log" "$stderr"
  local -a firmware=()
  if [[ "$mode" == "uefi" ]]; then
    local pair code vars_copy
    pair="$(find_ovmf)" || die "OVMF firmware pair not found"
    code="${pair%%|*}"
    vars_copy="$(mktemp "$WORK/OVMF_VARS.XXXXXX.fd")"
    cp "${pair#*|}" "$vars_copy"
    firmware=(-drive "if=pflash,format=raw,unit=0,readonly=on,file=$code"
              -drive "if=pflash,format=raw,unit=1,file=$vars_copy")
  fi
  set +e
  timeout --signal=TERM "$TIMEOUT_SECONDS" qemu-system-x86_64 \
    -machine accel=tcg -m 1024 -smp 2 -drive "file=$image,format=raw,if=ide,index=0" \
    -boot c -display none -monitor none -serial "file:$log" -no-reboot \
    "${firmware[@]}" >/dev/null 2>"$stderr"
  status=$?
  set -e
  [[ "$mode" != "uefi" ]] || rm -f "$vars_copy"
  if [[ "$status" -ne 124 && "$status" -ne 143 ]]; then
    cat "$stderr" >&2 || true
    cat "$log" >&2 || true
    die "$mode installed-disk QEMU exited unexpectedly (status $status)"
  fi
  if grep -Eqi 'Kernel panic|VFS: Unable to mount root|No working init found|Failed to execute /sbin/init' "$log"; then
    printf '%s\\n' "---- $mode boot failure signature ----" >&2
    grep -Ein 'Kernel panic|VFS: Unable to mount root|No working init found|Failed to execute /sbin/init' "$log" >&2 || true
    die "$mode boot emitted a fatal kernel/init failure"
  fi
  grep -Fq 'Vampire OS 0.1.0-dev | x86_64 live environment' "$log" || {
    cat "$log" >&2 || true
    die "$mode installed disk did not reach Vampire init"
  }
  grep -Eqi 'login:|Password:' "$log" || die "$mode installed disk did not reach serial login"
  printf 'PASS: %s installed disk reached Vampire OS init and serial login\n' "$mode"
}

run_boot bios
run_boot uefi
printf 'Installed-disk BIOS and UEFI boot tests passed. Images: %s\n' "$WORK"
