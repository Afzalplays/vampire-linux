# Hardware support policy

Initial target: x86_64 / AMD64, GRUB BIOS and UEFI boot, upstream Linux kernel
x86_64 defconfig, musl + BusyBox userspace, and QEMU TCG for virtual testing.

No physical device model is certified yet. A successful image build does not
prove Wi-Fi, audio, GPU acceleration, suspend, Bluetooth, touchpad or power
management compatibility.

Before listing a device as supported, record CPU, chipset, GPU, storage
controller, network adapters, firmware mode and test results for boot, storage,
network, graphics, audio, suspend/resume and shutdown. Proprietary firmware
redistribution must be reviewed separately.
