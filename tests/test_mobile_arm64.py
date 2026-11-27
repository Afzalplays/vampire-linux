import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
MOBILE = ROOT / "mobile"


class MobileArm64BringupTests(unittest.TestCase):
    def test_arm64_build_is_separate_from_desktop_x86_profile(self):
        config = (ROOT / "build" / "vampire_mobile_qemu_defconfig").read_text()
        desktop = (ROOT / "build" / "vampire_defconfig").read_text()
        self.assertIn("BR2_aarch64=y", config)
        self.assertIn("BR2_cortex_a53=y", config)
        self.assertIn("BR2_x86_64=y", desktop)
        self.assertNotIn("BR2_x86_64=y", config)

    def test_arm64_kernel_fragment_enables_qemu_virt_console_and_virtio(self):
        fragment = (ROOT / "build" / "vampire_mobile_qemu.fragment").read_text()
        for option in (
            "CONFIG_SERIAL_AMBA_PL011=y",
            "CONFIG_SERIAL_AMBA_PL011_CONSOLE=y",
            "CONFIG_VIRTIO=y",
            "CONFIG_VIRTIO_MMIO=y",
            "CONFIG_VIRTIO_BLK=y",
            "CONFIG_VIRTIO_NET=y",
            "CONFIG_VIRTIO_PCI=y",
            "CONFIG_VIRTIO_INPUT=y",
            "CONFIG_DRM_VIRTIO_GPU=y",
            "CONFIG_INPUT_EVDEV=y",
            "CONFIG_DEVTMPFS=y",
        ):
            with self.subTest(option=option):
                self.assertIn(option, fragment)

    def test_mobile_build_layers_mobile_overlay_and_kernel_fragment(self):
        script = (ROOT / "build" / "build-mobile-qemu.sh").read_text()
        self.assertIn("mobile/rootfs-overlay", script)
        self.assertIn("vampire_mobile_qemu.fragment", script)
        self.assertIn("BR2_PACKAGE_IPROUTE2=y", (ROOT / "build" / "vampire_mobile_qemu_defconfig").read_text())
        for option in ("BR2_PACKAGE_SDL2=y", "BR2_PACKAGE_SDL2_TTF=y", "BR2_PACKAGE_DEJAVU=y", "BR2_PACKAGE_VAMPIRE_MOBILE_SHELL=y"):
            self.assertIn(option, (ROOT / "build" / "vampire_mobile_qemu_defconfig").read_text())
        self.assertIn('rootfs.cpio.gz', script)
        self.assertIn('IMAGES="$BUILD_DIR/output/images"', script)
        self.assertIn('BR2_EXTERNAL="$ROOT_DIR/mobile/br2-external"', script)
        self.assertIn("BR2_PACKAGE_VAMPIRE_MOBILE_SHELL=y", (ROOT / "build" / "vampire_mobile_qemu_defconfig").read_text())

    def test_mobile_overlay_has_serial_console_and_no_desktop_installer(self):
        inittab = (MOBILE / "rootfs-overlay" / "etc" / "inittab").read_text()
        rc = (MOBILE / "rootfs-overlay" / "etc" / "init.d" / "rcS").read_text()
        os_release = (MOBILE / "rootfs-overlay" / "etc" / "os-release").read_text()
        menu = (MOBILE / "rootfs-overlay" / "usr" / "bin" / "vmobile").read_text()
        self.assertIn("ttyAMA0", inittab)
        self.assertIn("/usr/bin/vmobile-ui", inittab)
        self.assertIn("VAMPIRE MOBILE OS", rc)
        self.assertIn("ARM64 bring-up", os_release)
        self.assertNotIn("vinstall", menu)
        self.assertIn("Display and input devices", menu)
        self.assertIn("Launch touch UI", menu)
        shell = (MOBILE / "br2-external" / "package" / "vampire-mobile-shell" / "src" / "vampire-mobile-shell.c").read_text()
        self.assertIn("SDL_FINGERDOWN", shell)
        self.assertIn("VAMPIRE", shell)
        self.assertIn("SDL_VIDEODRIVER", (MOBILE / "rootfs-overlay" / "usr" / "bin" / "vmobile-ui").read_text())
        self.assertIn("sh /usr/bin/vmobile", (MOBILE / "rootfs-overlay" / "etc" / "profile.d" / "vampire-mobile.sh").read_text())


if __name__ == "__main__":
    unittest.main()
