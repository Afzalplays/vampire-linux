#!/usr/bin/env bash
# Build a minimal, independent Vampire OS live ISO using upstream Buildroot.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${VAMPIRE_BUILD_DIR:-$ROOT_DIR/.build}"
OUTPUT_DIR="${VAMPIRE_OUTPUT_DIR:-$ROOT_DIR/out}"
BUILDROOT_VERSION="${BUILDROOT_VERSION:-2025.02}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')}"
OVERLAY="$ROOT_DIR/rootfs-overlay"
ISO_ROOT="$BUILD_DIR/iso-root"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing host tool: $1"; }

for tool in git make gcc g++ perl python3 rsync cpio file patch bc bison flex \
            xorriso grub-mkrescue mformat; do
  need "$tool"
done

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$OVERLAY/usr/bin"
install -m 0755 "$ROOT_DIR/fetch/vfetch" "$OVERLAY/usr/bin/vfetch"
chmod 0755 "$OVERLAY/etc/init.d/rcS"

if [[ ! -d "$BUILD_DIR/buildroot/.git" ]]; then
  git clone --depth 1 --branch "$BUILDROOT_VERSION" \
    https://github.com/buildroot/buildroot.git "$BUILD_DIR/buildroot"
fi

BR_DIR="$BUILD_DIR/buildroot"
make -C "$BR_DIR" O="$BUILD_DIR/output" \
  BR2_DEFCONFIG="$ROOT_DIR/build/vampire_defconfig" defconfig

# Inject the local overlay path without storing machine-specific paths in Git.
sed -i "s|^BR2_ROOTFS_OVERLAY=.*|BR2_ROOTFS_OVERLAY=\"$OVERLAY\"|" \
  "$BUILD_DIR/output/.config"
make -C "$BR_DIR" O="$BUILD_DIR/output" olddefconfig
make -C "$BR_DIR" O="$BUILD_DIR/output" -j"$JOBS"

IMAGES="$BUILD_DIR/output/images"
[[ -s "$IMAGES/bzImage" ]] || die "Buildroot did not produce bzImage"
[[ -s "$IMAGES/rootfs.cpio.gz" ]] || die "Buildroot did not produce rootfs.cpio.gz"

rm -rf "$ISO_ROOT"
mkdir -p "$ISO_ROOT/boot/grub"
install -m 0644 "$IMAGES/bzImage" "$ISO_ROOT/boot/vmlinuz"
install -m 0644 "$IMAGES/rootfs.cpio.gz" "$ISO_ROOT/boot/initramfs.cpio.gz"
install -m 0644 "$OVERLAY/etc/os-release" "$ISO_ROOT/os-release"
install -m 0644 "$ROOT_DIR/build/grub.cfg" "$ISO_ROOT/boot/grub/grub.cfg"

ISO="$OUTPUT_DIR/vampire-os-0.1.0-dev-x86_64.iso"
grub-mkrescue -o "$ISO" "$ISO_ROOT"
(
  cd "$OUTPUT_DIR"
  sha256sum "$(basename "$ISO")" > "$(basename "$ISO").sha256"
)
printf '\nBuilt ISO: %s\n' "$ISO"
printf 'Checksum:  %s.sha256\n' "$ISO"
printf 'Boot mode: GRUB hybrid ISO (BIOS + UEFI, subject to host GRUB modules)\n'
