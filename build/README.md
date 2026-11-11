# Vampire OS live ISO build

This is the first bootable-image bring-up path. It builds a minimal x86_64
system from upstream Linux + Buildroot's musl toolchain and BusyBox userspace.
Buildroot is a build system, not the runtime base distribution.

## Host requirements

A Linux build host with Git, GCC/G++, Make, Perl, Python 3, rsync, cpio,
file, patch, bc, bison, flex, xorriso, GRUB rescue tools and mtools.

On Debian/Ubuntu build hosts, install the equivalent packages with the host
package manager. The host distribution is used only for build tools.

## Build

From the repository root:

```sh
chmod +x build/build-live-iso.sh
JOBS=4 ./build/build-live-iso.sh
```

Optional environment variables: `JOBS`, `BUILDROOT_VERSION`,
`VAMPIRE_BUILD_DIR`, and `VAMPIRE_OUTPUT_DIR`.

The script downloads the pinned Buildroot 2025.02 source tag, builds a
musl/BusyBox initramfs and upstream x86_64 Linux kernel, then packages them
with GRUB into a hybrid ISO and writes a SHA-256 checksum.

## Run in QEMU

```sh
qemu-system-x86_64 -m 2G -smp 2 -cdrom out/vampire-os-0.1.0-dev-desktop-x86_64.iso -boot d
```

Use `-enable-kvm` when KVM is available. The first image is a console-only
live bring-up image. It is not the graphical Desktop edition, does not install
to disk, and is not a production release. BIOS/UEFI boot must be validated on
real firmware and virtual machines before release.

The image includes the Vampire OS identity and BusyBox console. The build
script stages the repository's `vfetch` utility into the target filesystem
before compilation.


The current defconfig also enables eudev, Weston DRM desktop-shell support,
Python 3 (TLS and zlib), and Minisign. These increase image size and build time.
Weston is an upstream graphical bring-up layer; it is not the final Vampire
Desktop. VPM is copied into the root filesystem for development, but ships
without a configured package repository.
