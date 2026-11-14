#!/usr/bin/env python3
import pathlib
import stat
import subprocess
import sys
import tarfile
import tempfile

SCRIPT = pathlib.Path(__file__).with_name("stage-rootfs.py")


def make_tar(path, members):
    with tarfile.open(path, "w") as tar:
        for name, data in members:
            info = tarfile.TarInfo(name)
            info.size = len(data)
            import io
            tar.addfile(info, io.BytesIO(data))


def run(archive, dest):
    return subprocess.run([sys.executable, str(SCRIPT), str(archive), str(dest)],
                          text=True, capture_output=True)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        good = root / "rootfs.tar"
        make_tar(good, [("etc/os-release", b"NAME=Vampire OS\n"),
                        ("sbin/init", b"init"), ("bin/busybox", b"busybox")])
        # Verify OS permission metadata survives the staging extraction.
        with tarfile.open(good, "a") as tar:
            info = tarfile.TarInfo("usr/bin/vampire-test-suid")
            info.size = 4
            info.mode = 0o4755
            import io
            tar.addfile(info, io.BytesIO(b"test"))
            link = tarfile.TarInfo("etc/mtab")
            link.type = tarfile.SYMTYPE
            link.linkname = "/proc/mounts"
            tar.addfile(link)
        dest = root / "stage"
        result = run(good, dest)
        assert result.returncode == 0, result.stderr
        assert (dest / "etc/os-release").is_file()
        assert stat.S_IMODE((dest / "usr/bin/vampire-test-suid").stat().st_mode) == 0o4755
        assert (dest / "etc/mtab").is_symlink()
        assert pathlib.Path(dest / "etc/mtab").readlink().as_posix() == "../proc/mounts"
        assert "No disk partitioning" in result.stdout

        nonempty = root / "not-empty"
        nonempty.mkdir()
        (nonempty / "keep").write_text("safe")
        result = run(good, nonempty)
        assert result.returncode != 0
        assert (nonempty / "keep").read_text() == "safe"

        bad = root / "bad.tar"
        make_tar(bad, [("../escape", b"x"), ("etc/os-release", b"x"),
                       ("sbin/init", b"x"), ("bin/busybox", b"x")])
        result = run(bad, root / "bad-stage")
        assert result.returncode != 0
        assert not (root / "escape").exists()

        bad_link = root / "bad-link.tar"
        with tarfile.open(bad_link, "w") as tar:
            for name, data in (("etc/os-release", b"x"), ("sbin/init", b"x"),
                               ("bin/busybox", b"x")):
                info = tarfile.TarInfo(name)
                info.size = len(data)
                tar.addfile(info, io.BytesIO(data))
            link = tarfile.TarInfo("etc/escape")
            link.type = tarfile.SYMTYPE
            link.linkname = "../../outside"
            tar.addfile(link)
        result = run(bad_link, root / "bad-link-stage")
        assert result.returncode != 0
        assert not (root / "outside").exists()

        incomplete = root / "incomplete.tar"
        make_tar(incomplete, [("etc/os-release", b"x")])
        result = run(incomplete, root / "incomplete-stage")
        assert result.returncode != 0
    print("rootfs staging safety tests: PASS")


if __name__ == "__main__":
    main()
