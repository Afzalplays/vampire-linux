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
            source.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
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
        passwd = (target / "etc/passwd").read_text(encoding="utf-8").splitlines()
        vampire = next(line.split(":") for line in passwd if line.startswith("vampire:"))
        assert vampire[2:4] == ["1000", "1000"], vampire
        assert vampire[5:] == ["/home/vampire", "/bin/sh"], vampire
        groups = {
            fields[0]: (int(fields[2]), set(fields[3].split(",")) if fields[3] else set())
            for fields in (line.split(":") for line in (target / "etc/group").read_text(encoding="utf-8").splitlines())
        }
        for name, expected_gid in (("vampire", 1000), ("video", 27), ("input", 100), ("render", 107), ("audio", 29)):
            assert name in groups, name
            assert groups[name][0] == expected_gid, (name, groups[name])
            assert "vampire" in groups[name][1], (name, groups[name])
        shadow = next(line.split(":") for line in (target / "etc/shadow").read_text(encoding="utf-8").splitlines() if line.startswith("vampire:"))
        assert shadow[1] == "!", shadow
        assert (target / "etc/shadow").stat().st_mode & 0o777 == 0o640
        assert (target / "home/vampire").is_dir()
        for relative in (
            "usr/bin/vdesktop-session",
            "usr/lib/vampire/session-runtime",
            "usr/lib/vampire/settings-bootstrap",
        ):
            staged = target / relative
            assert staged.read_text(encoding="utf-8").startswith("#!/bin/sh")
            assert staged.stat().st_mode & 0o777 == 0o755
        # Never silently accept an image that already contains a conflicting
        # local account: the graphical session and device permissions assume
        # this exact unprivileged identity.
        conflict = root / "conflicting-target"
        (conflict / "etc").mkdir(parents=True)
        (conflict / "etc/passwd").write_text(
            "root:x:0:0:root:/root:/bin/sh\nvampire:x:1001:1000:Vampire:/home/vampire:/bin/sh\n",
            encoding="utf-8",
        )
        (conflict / "etc/group").write_text("root:x:0:\n", encoding="utf-8")
        (conflict / "etc/shadow").write_text("root:*:19000:0:99999:7:::\nvampire:!:19000:0:99999:7:::\n", encoding="utf-8")
        conflict_kernel = binaries / "conflict-bzImage"
        conflict_kernel.write_bytes(b"test-kernel-image")
        conflict_env = dict(env, BINARIES_DIR=str(binaries))
        (binaries / "bzImage").write_bytes(conflict_kernel.read_bytes())
        result = subprocess.run([sys.executable, str(SCRIPT), str(conflict)],
                                env=conflict_env, text=True, capture_output=True)
        assert result.returncode != 0
        assert "existing 'vampire' account conflicts" in result.stderr, result.stderr

        (target / "boot/vmlinuz").unlink()
        kernel.unlink()
        result = subprocess.run([sys.executable, str(SCRIPT), str(target)],
                                env=env, text=True, capture_output=True)
        assert result.returncode != 0
        assert not (target / "boot/vmlinuz").exists()
    print("Vampire rootfs kernel embedding tests: PASS")


if __name__ == "__main__":
    main()
