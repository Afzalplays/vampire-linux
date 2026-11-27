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

Use `-enable-kvm` when KVM is available. The live image is a console-first developer environment with an experimental text-mode disk installer. The installer can discover its rootfs payload on the boot ISO and perform a confirmation-gated erase-and-install to a whole disk for BIOS or UEFI. It is not a graphical installer or production release; BIOS/UEFI installation to disposable virtual disks and installed-disk reboot must pass before release.

The image includes the Vampire OS identity and BusyBox console. The build
script stages the repository's `vfetch` utility into the target filesystem
before compilation.


The current defconfig also enables eudev, Weston DRM desktop-shell support,
Python 3 (TLS and zlib), and Minisign. These increase image size and build time.
Weston is an upstream graphical bring-up layer; it is not the final Vampire
Desktop. VPM is copied into the root filesystem for development, but ships
without a configured package repository.


## Separate editions

- Desktop: `bash build/build-live-iso.sh` (Weston DRM preview enabled).
- Server: `VAMPIRE_EDITION=server bash build/build-live-iso.sh` (Weston omitted; Dropbear tools included but SSH is not auto-started).

The build outputs are isolated in `.build/output-desktop` and
`.build/output-server`, and ISO names include the edition. Test either image
with the same `VAMPIRE_EDITION` value passed to `scripts/test-live-iso.sh`.

## ARM64 mobile bring-up (QEMU)

`build/build-mobile-qemu.sh` builds a separate AArch64 Buildroot kernel + initramfs profile for QEMU's generic `virt` machine. This is a console bring-up target for validating the ARM64 toolchain, kernel and initramfs path; it is **not** a device image and does not imply phone hardware support. The target has no phone modem, camera, touchscreen or vendor firmware integration. See `docs/MOBILE-SUPPORT.md` before treating any artifact as installable.


## Mobile ARM64 QEMU console

The ARM64 image now uses a separate mobile rootfs overlay: it prints an architecture-aware Vampire Mobile boot banner, starts a PL011 serial getty on `ttyAMA0`, and provides the honest early bring-up menu via `vmobile`. The menu exposes only operations actually present in this console image; it does not pretend to control phone radios, camera, touch, sensors or lock screen. The build script merges the ARM64 QEMU kernel fragment and layers `mobile/rootfs-overlay` over the shared base rootfs.
