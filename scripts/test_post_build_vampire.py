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
        kernel = binaries / "bzImage"
        kernel.write_bytes(b"test-kernel-image")
        env = dict(os.environ, BINARIES_DIR=str(binaries))
        result = subprocess.run([sys.executable, str(SCRIPT), str(target)],
                                env=env, text=True, capture_output=True)
        assert result.returncode == 0, result.stderr
        assert (target / "boot/vmlinuz").read_bytes() == kernel.read_bytes()
        (target / "boot/vmlinuz").unlink()
        kernel.unlink()
        result = subprocess.run([sys.executable, str(SCRIPT), str(target)],
                                env=env, text=True, capture_output=True)
        assert result.returncode != 0
        assert not (target / "boot/vmlinuz").exists()
    print("Vampire rootfs kernel embedding tests: PASS")


if __name__ == "__main__":
    main()
