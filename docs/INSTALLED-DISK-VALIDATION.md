# Installed-Disk BIOS/UEFI Validation

This test validates the installed system independently of the live ISO. It creates disposable 8 GiB disk images, runs the production `vinstall install` path, inspects the installed root filesystem, and boots the resulting disk under QEMU in both legacy BIOS and UEFI mode.

## Safety and scope

- Run this only on a disposable Linux build machine or VM. The test uses loop devices, mounts filesystems, and invokes privileged installer operations through `sudo`.
- The script creates files only under `VAMPIRE_INSTALL_TEST_DIR`; it refuses to overwrite existing `bios.img` or `uefi.img` files and refuses unsafe work directories.
- Do not point the test at a real customer disk or production block device.
- A passing result proves the installed disk reached Vampire init, serial login, and DHCP under QEMU. It does not prove compatibility with every physical GPU, Wi-Fi adapter, firmware implementation, or display panel.

## Build prerequisites

Build the edition first with the project's Buildroot ISO script. The host needs the build tools listed by `build/build-live-iso.sh`. The installed-disk test additionally requires:

- `sudo`, loop-device support, `losetup`, `parted`, `partprobe`, `udevadm`
- `mkfs.ext4`, `mkfs.fat`, `mount`, `umount`, `blkid`, `grub-install`
- `qemu-system-x86_64`, `timeout`, `tar`, `sha256sum`, `python3`
- For UEFI: a matching OVMF code and variables firmware pair, normally under `/usr/share/OVMF` or `/usr/share/ovmf`

## Build and test Desktop

```bash
./build/build-live-iso.sh
VAMPIRE_EDITION=desktop VAMPIRE_INSTALL_TEST_DIR="$PWD/out/installed-disk-tests-desktop-$(date +%s)" ./scripts/test-installed-disk.sh
```

## Build and test Server

```bash
VAMPIRE_EDITION=server ./build/build-live-iso.sh
VAMPIRE_EDITION=server VAMPIRE_INSTALL_TEST_DIR="$PWD/out/installed-disk-tests-server-$(date +%s)" ./scripts/test-installed-disk.sh
```

The test defaults to the Desktop edition. Set `VAMPIRE_EDITION=server` for the Server rootfs. The corresponding rootfs archive and checksum must already exist in `out/`.

## Optional settings

| Variable | Default | Purpose |
| --- | --- | --- |
| `VAMPIRE_EDITION` | `desktop` | Select `desktop` or `server`. |
| `VAMPIRE_INSTALL_TEST_DIR` | `out/installed-disk-tests` | Directory for disk images, serial logs, and inspection logs. Must be a dedicated disposable directory. |
| `VAMPIRE_INSTALLED_BOOT_TIMEOUT` | `60` | QEMU boot observation window in seconds (1–86400). |
| `VAMPIRE_OVMF_DIR` | auto-detected | Directory containing a matching OVMF code/variables pair. |

Use a fresh test directory for each run because existing disk images are deliberately not overwritten.

## Expected result and diagnostics

A successful run prints both:

```text
PASS: bios installed disk reached Vampire OS init and serial login
PASS: uefi installed disk reached Vampire OS init and serial login
Installed-disk BIOS and UEFI boot tests passed.
```

Inspect the selected test directory when a run fails. The most useful files include:

- `bios.serial.log` / `uefi.serial.log`: guest serial console output.
- `bios.qemu.stderr` / `uefi.qemu.stderr`: QEMU diagnostics.
- `*.vfetch.log`, `*.settings-*.log`, and `*.display-*.log`: installed-userland checks.
- `*.installer-check.log`: installed installer system-check output.

The script cleans up loop devices and mounts on exit. If the host is interrupted or loses power during a privileged operation, inspect `findmnt` and `losetup -a` before manually cleaning up any remaining test mounts or loop devices.
