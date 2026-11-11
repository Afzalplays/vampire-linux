#!/usr/bin/env bash
# Boot the built ISO in legacy BIOS and UEFI firmware and verify the live init.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$ROOT_DIR/out/vampire-os-0.1.0-dev-x86_64.iso}"
LOG_DIR="${VAMPIRE_QEMU_LOG_DIR:-$ROOT_DIR/out/qemu-logs}"
TIMEOUT_SECONDS="${VAMPIRE_QEMU_TIMEOUT:-75}"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing test tool: $1"; }
need qemu-system-x86_64
need timeout
[[ -s "$ISO" ]] || die "ISO not found: $ISO"
mkdir -p "$LOG_DIR"

run_boot() {
  local mode="$1"
  local log="$LOG_DIR/$mode.log"
  local -a firmware=()
  if [[ "$mode" == "uefi" ]]; then
    local ovmf
    ovmf="$(find /usr/share/OVMF /usr/share/ovmf -type f \\( -name 'OVMF_CODE.fd' -o -name 'OVMF_CODE_4M.fd' \\) -print -quit 2>/dev/null || true)"
    [[ -n "$ovmf" ]] || die "UEFI firmware (OVMF_CODE.fd) not found"
    firmware=(-bios "$ovmf")
  fi

  rm -f "$log"
  # QEMU is expected to be stopped by timeout after the login prompt appears.
  timeout --signal=TERM "$TIMEOUT_SECONDS" qemu-system-x86_64 \\
    -machine accel=tcg -m 1024 -smp 2 -cdrom "$ISO" -boot d \\
    -display none -monitor none -serial "file:$log" -no-reboot \\
    "${firmware[@]}" >/dev/null 2>&1 || {
      status=$?
      [[ "$status" -eq 124 || "$status" -eq 143 ]] || die "$mode QEMU exited unexpectedly (status $status)"
    }

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
