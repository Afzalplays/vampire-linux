#!/usr/bin/env bash
# Build an ARM64 Vampire Mobile bring-up image for QEMU virt (not a phone image).
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${VAMPIRE_MOBILE_BUILD_DIR:-$ROOT_DIR/.build/mobile-arm64}"
OUTPUT_DIR="${VAMPIRE_MOBILE_OUTPUT_DIR:-$ROOT_DIR/out/mobile-arm64}"
BUILDROOT_VERSION="${BUILDROOT_VERSION:-2025.02}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')}"
need(){ command -v "$1" >/dev/null 2>&1 || { printf 'Missing host tool: %s\n' "$1" >&2; exit 1; }; }
for tool in git make gcc g++ perl python3 rsync cpio file patch bc bison flex wget; do need "$tool"; done
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
git check-ref-format "refs/tags/$BUILDROOT_VERSION" >/dev/null
if [[ ! -d "$BUILD_DIR/buildroot/.git" ]]; then
  git clone --depth 1 --branch "$BUILDROOT_VERSION" https://github.com/buildroot/buildroot.git "$BUILD_DIR/buildroot"
else
  git -C "$BUILD_DIR/buildroot" fetch --depth 1 origin "refs/tags/$BUILDROOT_VERSION:refs/tags/$BUILDROOT_VERSION"
  git -C "$BUILD_DIR/buildroot" checkout --detach "$BUILDROOT_VERSION"
fi
BR_DIR="$BUILD_DIR/buildroot"
[[ "$(git -C "$BR_DIR" describe --tags --exact-match HEAD)" == "$BUILDROOT_VERSION" ]]
make -C "$BR_DIR" O="$BUILD_DIR/output" BR2_DEFCONFIG="$ROOT_DIR/build/vampire_mobile_qemu_defconfig" defconfig
sed -i "s|^BR2_ROOTFS_OVERLAY=.*|BR2_ROOTFS_OVERLAY=\\\"$ROOT_DIR/rootfs-overlay:$ROOT_DIR/mobile/rootfs-overlay\\\"|" "$BUILD_DIR/output/.config"
sed -i "s|^BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=.*|BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=\\\"$ROOT_DIR/build/vampire_mobile_qemu.fragment\\\"|" "$BUILD_DIR/output/.config"
make -C "$BR_DIR" O="$BUILD_DIR/output" olddefconfig
make -C "$BR_DIR" O="$BUILD_DIR/output" -j"$JOBS"
IMAGES="$BUILD_DIR/output/images"
[[ -s "$IMAGES/Image" ]] || { printf 'ARM64 kernel Image missing\n' >&2; exit 1; }
[[ -s "$IMAGES/rootfs.cpio.gz" ]] || { printf 'ARM64 initramfs missing\n' >&2; exit 1; }
install -m 0644 "$IMAGES/Image" "$OUTPUT_DIR/Image"
install -m 0644 "$IMAGES/rootfs.cpio.gz" "$OUTPUT_DIR/rootfs.cpio.gz"
(cd "$OUTPUT_DIR" && sha256sum Image rootfs.cpio.gz > SHA256SUMS)
printf 'ARM64 QEMU bring-up artifacts: %s\n' "$OUTPUT_DIR"
printf 'Boot with: qemu-system-aarch64 -machine virt -cpu cortex-a57 -m 2G -kernel %q -initrd %q -append "console=ttyAMA0" -nographic\n' "$OUTPUT_DIR/Image" "$OUTPUT_DIR/rootfs.cpio.gz"
