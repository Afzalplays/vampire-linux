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
`/usr/share/ovmf` paths. Set `VAMPIRE_QEMU_TIMEOUT` to adjust the per-mode
boot window and `VAMPIRE_QEMU_LOG_DIR` to change the log directory.
