import os
import pathlib
import subprocess
import sys
import tempfile

SCRIPT = pathlib.Path(__file__).with_name("post-build-vampire.py")


def main():
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        target = root / "target"
        binaries = root / "images"
        target.mkdir()
        binaries.mkdir()
        overlay = root / "overlay"
        for relative in (
            "usr/bin/vdesktop-session",
            "usr/lib/vampire/session-runtime",
            "usr/lib/vampire/settings-bootstrap",
        ):
            source = overlay / relative
            source.parent.mkdir(parents=True, exist_ok=True)
            source.write_text("#!/bin/sh\\nexit 0\\n", encoding="utf-8")
            source.chmod(0o644)
        kernel = binaries / "bzImage"
        kernel.write_bytes(b"test-kernel-image")
        env = dict(
            os.environ,
            BINARIES_DIR=str(binaries),
            VAMPIRE_EDITION="desktop",
            VAMPIRE_ROOTFS_OVERLAY=str(overlay),
        )
        result = subprocess.run([sys.executable, str(SCRIPT), str(target)],
                                env=env, text=True, capture_output=True)
        assert result.returncode == 0, result.stderr
        assert (target / "boot/vmlinuz").read_bytes() == kernel.read_bytes()
        for relative in (
            "usr/bin/vdesktop-session",
            "usr/lib/vampire/session-runtime",
            "usr/lib/vampire/settings-bootstrap",
        ):
            staged = target / relative
            assert staged.read_text(encoding="utf-8").startswith("#!/bin/sh")
            assert staged.stat().st_mode & 0o777 == 0o755
        (target / "boot/vmlinuz").unlink()
        kernel.unlink()
        result = subprocess.run([sys.executable, str(SCRIPT), str(target)],
                                env=env, text=True, capture_output=True)
        assert result.returncode != 0
        assert not (target / "boot/vmlinuz").exists()
    print("Vampire rootfs kernel embedding tests: PASS")


if __name__ == "__main__":
    main()
