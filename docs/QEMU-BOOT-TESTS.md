# QEMU live-image boot tests

The live-image test boots the same ISO once with SeaBIOS (legacy BIOS) and
once with OVMF (UEFI). The UEFI run uses a matching OVMF CODE and VARS pflash
pair. CODE is read-only; the test copies the VARS template to a temporary
writable file and removes that copy after QEMU exits.

QEMU stderr and serial output are retained under `out/qemu-logs/`. A test
passes only when the serial console reaches the Vampire OS live-init banner
and a login prompt. A successful ISO build alone is not a boot test.

Run locally after building:

```sh
bash scripts/test-live-iso.sh
VAMPIRE_EDITION=server bash scripts/test-live-iso.sh
```

The test requires QEMU x86 system emulation and OVMF firmware. Set
`VAMPIRE_OVMF_DIR` to a directory containing a matching firmware pair when
OVMF is installed outside the standard `/usr/share/OVMF` or
`/usr/share/ovmf` paths. The same variable is honored by the disposable installed-disk
test. Set `VAMPIRE_INSTALL_TEST_DIR` to retain test images and serial/QEMU logs
outside the default `out/installed-disk-tests/` directory; the harness refuses
to overwrite existing BIOS or UEFI disk images. Set `VAMPIRE_QEMU_TIMEOUT` to adjust the per-mode
boot window and `VAMPIRE_QEMU_LOG_DIR` to change the log directory.


## Installed-disk BIOS and UEFI tests

The installed-disk harness creates fresh 8 GiB disposable images, attaches loop devices, and invokes the same `vinstall install` path shipped in the live ISO. It then boots each installed image under SeaBIOS and OVMF and requires both the installed-system init banner and a serial getty prompt. Kernel panic, missing root filesystem, missing init, unexpected QEMU exit, or failure to reach login fails the test. It never reuses or overwrites existing disk images.

Run after the edition rootfs archive and kernel have been built:

```sh
sudo -E bash scripts/test-installed-disk.sh
sudo -E env VAMPIRE_EDITION=server bash scripts/test-installed-disk.sh
```

The UEFI installer explicitly embeds the GPT, ext-family, FAT, filesystem-UUID search and GRUB configfile modules into the removable EFI bootloader, so the firmware handoff does not depend on loading those modules from an unmounted filesystem. This was added in commit `4bf29feb635d9f05fc03d2491473883ced9e3cbf`; it is a configuration fix, not proof that an installed UEFI disk has booted successfully.\n\nThe harness requires loop-device access, `sudo`, partitioning and filesystem tools, GRUB BIOS/UEFI utilities, QEMU, OVMF, and the matching Buildroot output under `.build/output-<edition>/images/`. Set `VAMPIRE_INSTALLED_BOOT_TIMEOUT` to change the boot window (1–86400 seconds). Logs and disk images are retained in `out/installed-disk-tests/`; choose another fresh location with `VAMPIRE_INSTALL_TEST_DIR`.
