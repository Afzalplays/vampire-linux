#!/usr/bin/env bash
# Create disposable BIOS/UEFI disk images, install the staged rootfs and boot them in QEMU.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EDITION="${VAMPIRE_EDITION:-desktop}"
case "$EDITION" in desktop|server) ;; *) printf 'ERROR: unsupported edition: %s\\n' "$EDITION" >&2; exit 2 ;; esac
ROOTFS_TAR="$ROOT_DIR/out/vampire-os-0.1.0-dev-$EDITION-x86_64-rootfs.tar"
WORK="${VAMPIRE_INSTALL_TEST_DIR:-$ROOT_DIR/out/installed-disk-tests}"
TIMEOUT_SECONDS="${VAMPIRE_INSTALLED_BOOT_TIMEOUT:-60}"
case "$TIMEOUT_SECONDS" in ""|*[!0-9]*) printf 'ERROR: VAMPIRE_INSTALLED_BOOT_TIMEOUT must be a positive integer.\\n' >&2; exit 2 ;; esac
(( ${#TIMEOUT_SECONDS} <= 5 )) || { printf 'ERROR: VAMPIRE_INSTALLED_BOOT_TIMEOUT must be between 1 and 86400 seconds.\\n' >&2; exit 2; }
TIMEOUT_SECONDS=$((10#$TIMEOUT_SECONDS))
(( TIMEOUT_SECONDS > 0 && TIMEOUT_SECONDS <= 86400 )) || { printf 'ERROR: VAMPIRE_INSTALLED_BOOT_TIMEOUT must be between 1 and 86400 seconds.\\n' >&2; exit 2; }
LOOPS=()
VARS_FILES=()
INSPECT_MOUNT=
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing test tool: $1"; }
WORK_ABS="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$WORK")"
check_path="$WORK_ABS"
while [[ "$check_path" != / ]]; do
  [[ ! -L "$check_path" ]] || die "Refusing a symlinked test path component: $check_path"
  check_path="$(dirname -- "$check_path")"
done
mkdir -p "$WORK"
WORK="$(cd -- "$WORK" && pwd -P)"
[[ "$WORK" != / && "$WORK" != "$ROOT_DIR" ]] || die "Refusing an unsafe test directory: $WORK"
[[ -s "$ROOTFS_TAR.sha256" ]] || die "Missing rootfs checksum: $ROOTFS_TAR.sha256"
[[ -s "$ROOTFS_TAR" ]] || die "Missing rootfs archive: $ROOTFS_TAR"
for tool in sudo losetup parted partprobe udevadm mkfs.ext4 mkfs.fat mount umount blkid grub-install qemu-system-x86_64 timeout tar sha256sum python3 truncate cp rm grep; do need "$tool"; done
for mode in bios uefi; do
  [[ ! -e "$WORK/$mode.img" && ! -L "$WORK/$mode.img" ]] || die "Refusing to overwrite an existing test disk image: $WORK/$mode.img"
done
VAMPIRE_ROOTFS_STAGE="$ROOT_DIR/scripts/stage-rootfs.py" "$ROOT_DIR/rootfs-overlay/usr/bin/vinstall" validate "$ROOTFS_TAR"
cleanup() {
  set +e
  if [[ -n "$INSPECT_MOUNT" ]]; then sudo umount "$INSPECT_MOUNT" >/dev/null 2>&1 || true; fi
  for loop in "${LOOPS[@]}"; do sudo losetup -d "$loop" >/dev/null 2>&1 || true; done
  for vars_file in "${VARS_FILES[@]}"; do rm -f -- "$vars_file"; done
}
trap cleanup EXIT HUP INT TERM

find_ovmf() {
  local dir candidate vars
  local -a dirs=()
  if [[ -n "${VAMPIRE_OVMF_DIR:-}" ]]; then
    dirs+=("$VAMPIRE_OVMF_DIR")
  else
    dirs+=(/usr/share/OVMF /usr/share/ovmf)
  fi
  for dir in "${dirs[@]}"; do
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

  # Detach the loop device before QEMU opens the same backing image. This
  # prevents the host block layer and QEMU from holding concurrent views of
  # the test disk and makes the boot test exercise the flushed disk image.
  sudo losetup -d "$loop"
  LOOPS=()
  udevadm settle

  # Inspect the installed root filesystem independently of the boot log.
  # This catches incomplete staging/configuration even if GRUB reaches init.
  loop="$(sudo losetup --find --show --partscan "$image")"
  LOOPS+=("$loop")
  INSPECT_MOUNT="$WORK/inspect-$mode"
  mkdir -p "$INSPECT_MOUNT"
  sudo mount -o ro,noload "${loop}p2" "$INSPECT_MOUNT" || die "$mode installed root partition could not be mounted read-only"
  local root_partuuid
  root_partuuid="$(sudo blkid -s PARTUUID -o value "${loop}p2")"
  [[ -n "$root_partuuid" ]] || die "$mode installed root partition has no PARTUUID"
  for required in usr/bin/vfetch usr/bin/vpower usr/bin/vsettings etc/init.d/rcS etc/inittab etc/fstab etc/vampire/install.conf boot/vmlinuz boot/grub/grub.cfg; do
    [[ -s "$INSPECT_MOUNT/$required" ]] || die "$mode installed root is missing required file: /$required"
  done
  [[ -x "$INSPECT_MOUNT/usr/bin/vfetch" ]] || die "$mode installed VFetch is not executable"
  grep -Fxq "FIRMWARE=$mode" "$INSPECT_MOUNT/etc/vampire/install.conf" || die "$mode installed firmware metadata is incorrect"
  grep -Fq "root=PARTUUID=$root_partuuid" "$INSPECT_MOUNT/boot/grub/grub.cfg" || die "$mode GRUB root PARTUUID does not match the installed partition"
  grep -Fq ' / ext4 ' "$INSPECT_MOUNT/etc/fstab" || die "$mode installed fstab does not mount the root filesystem"
  if [[ "$EDITION" == desktop ]]; then
    for required in usr/bin/vdesktop usr/bin/vgraphical usr/bin/vampire-terminal usr/lib/vampire/settings_apply.py etc/xdg/weston/weston.ini etc/xdg/foot/foot.ini; do
      [[ -s "$INSPECT_MOUNT/$required" ]] || die "$mode Desktop install is missing /$required"
    done
    grep -Fxq 'alpha=0.90' "$INSPECT_MOUNT/etc/xdg/foot/foot.ini" || die "$mode installed Desktop terminal transparency default is incorrect"
  fi

  # Execute the installed userland in an isolated chroot, not merely inspect
  # that files exist. This catches missing interpreters, broken symlinks and
  # runtime dependencies before the disk is handed to QEMU.
  sudo chroot "$INSPECT_MOUNT" /usr/bin/vfetch > "$WORK/$mode.vfetch.log" 2>&1 || die "$mode installed VFetch failed to execute"
  grep -Fq 'V A M P I R E' "$WORK/$mode.vfetch.log" || die "$mode installed VFetch did not render the Vampire logo"
  grep -Fq 'Kernel:' "$WORK/$mode.vfetch.log" || die "$mode installed VFetch omitted kernel information"
  grep -Fq 'Memory:' "$WORK/$mode.vfetch.log" || die "$mode installed VFetch omitted memory information"

  sudo chroot "$INSPECT_MOUNT" /bin/sh /usr/bin/vpower status > "$WORK/$mode.vpower.log" 2>&1 || die "$mode installed vpower status failed"
  grep -Fq 'Vampire OS power status' "$WORK/$mode.vpower.log" || die "$mode installed vpower status output is invalid"
  if sudo chroot "$INSPECT_MOUNT" /bin/sh /usr/bin/vpower reboot > "$WORK/$mode.vpower-reject.log" 2>&1; then
    die "$mode installed vpower accepted reboot without explicit confirmation"
  fi
  grep -Fq 'refusing reboot without the explicit --yes flag' "$WORK/$mode.vpower-reject.log" || die "$mode installed vpower did not safely reject an unconfirmed reboot"

  sudo chroot "$INSPECT_MOUNT" /bin/sh /usr/bin/vinstall system-check > "$WORK/$mode.installer-check.log" 2>&1 || die "$mode installed installer system-check failed"
  grep -Fq 'Architecture: x86_64' "$WORK/$mode.installer-check.log" || die "$mode installed installer system-check omitted architecture"

  sudo umount "$INSPECT_MOUNT"
  INSPECT_MOUNT=
  sudo losetup -d "$loop"
  LOOPS=()
  udevadm settle

  rm -f "$log" "$stderr"
  local -a firmware=()
  if [[ "$mode" == "uefi" ]]; then
    local pair code vars_copy
    pair="$(find_ovmf)" || die "OVMF firmware pair not found"
    code="${pair%%|*}"
    vars_copy="$(mktemp "$WORK/OVMF_VARS.XXXXXX.fd")"
    VARS_FILES+=("$vars_copy")
    cp "${pair#*|}" "$vars_copy"
    firmware=(-drive "if=pflash,format=raw,unit=0,readonly=on,file=$code"
              -drive "if=pflash,format=raw,unit=1,file=$vars_copy")
  fi
  set +e
  timeout --signal=TERM "$TIMEOUT_SECONDS" qemu-system-x86_64 \
    -machine accel=tcg -m 1024 -smp 2 -drive "file=$image,format=raw,if=ide,index=0" \
    -nic user,model=e1000 -boot c -display none -monitor none -serial "file:$log" -no-reboot \
    "${firmware[@]}" >/dev/null 2>"$stderr"
  status=$?
  set -e
  if [[ "$mode" == "uefi" ]]; then
    rm -f -- "$vars_copy"
  fi
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
  grep -Fq 'Vampire OS 0.1.0-dev | x86_64 installed system' "$log" || {
    cat "$log" >&2 || true
    die "$mode installed disk did not reach Vampire init"
  }
  grep -Eqi 'login:|Password:' "$log" || die "$mode installed disk did not reach serial login"
  grep -Eqi 'udhcpc: lease of .* obtained' "$log" || die "$mode installed disk did not obtain a DHCP lease"
  printf 'PASS: %s installed disk reached Vampire OS init and serial login\n' "$mode"
}

run_boot bios
run_boot uefi
printf 'Installed-disk BIOS and UEFI boot tests passed. Images: %s\n' "$WORK"
