# QEMU live-image boot tests

The live-image test boots the same ISO once with SeaBIOS (legacy BIOS) and
once with OVMF (UEFI). The UEFI run uses the matching OVMF CODE and VARS
pflash pair: CODE is read-only, while a fresh writable copy of VARS is used
for each run so test state never modifies the host firmware template.

QEMU's stderr is retained beside each serial log under `out/qemu-logs/`.
A test passes only when the serial console reaches the Vampire OS live-init
banner and a login prompt. A successful ISO build alone is not a boot test.

Run locally after building:

```sh
bash scripts/test-live-iso.sh
VAMPIRE_EDITION=server bash scripts/test-live-iso.sh
```

Required host packages include QEMU x86 system emulation and OVMF firmware.
