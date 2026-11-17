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
            devnull = tarfile.TarInfo("dev/null")
            devnull.type = tarfile.CHRTYPE
            devnull.devmajor = 1
            devnull.devminor = 3
            tar.addfile(devnull)
        dest = root / "stage"
        result = run(good, dest)
        assert result.returncode == 0, result.stderr
        assert (dest / "etc/os-release").is_file()
        assert stat.S_IMODE((dest / "usr/bin/vampire-test-suid").stat().st_mode) == 0o4755
        assert (dest / "etc/mtab").is_symlink()
        assert pathlib.Path(dest / "etc/mtab").readlink().as_posix() == "../proc/mounts"
        assert not (dest / "dev/null").exists()
        assert "No disk partitioning" in result.stdout

        # GNU tar emits a root "." directory when archiving with -C ROOT .
        root_marker_tar = root / "root-marker.tar"
        with tarfile.open(root_marker_tar, "w") as tar:
            root_entry = tarfile.TarInfo(".")
            root_entry.type = tarfile.DIRTYPE
            tar.addfile(root_entry)
            for name, data in (("etc/os-release", b"NAME=Vampire OS\n"),
                               ("sbin/init", b"init"), ("bin/busybox", b"busybox")):
                info = tarfile.TarInfo(name)
                info.size = len(data)
                tar.addfile(info, io.BytesIO(data))
        root_marker_dest = root / "root-marker-stage"
        result = run(root_marker_tar, root_marker_dest)
        assert result.returncode == 0, result.stderr
        assert (root_marker_dest / "etc/os-release").is_file()

        # A newly formatted ext4 target contains an empty lost+found.
        ext4_target = root / "ext4-target"
        ext4_target.mkdir()
        (ext4_target / "lost+found").mkdir()
        result = run(good, ext4_target)
        assert result.returncode == 0, result.stderr
        assert (ext4_target / "lost+found").is_dir()
        assert (ext4_target / "etc/os-release").is_file()

        nonempty = root / "not-empty"
        nonempty.mkdir()
        (nonempty / "keep").write_text("safe")
        result = run(good, nonempty)
        assert result.returncode != 0
        assert (nonempty / "keep").read_text() == "safe"

        occupied_lost_found = root / "occupied-lost-found"
        occupied_lost_found.mkdir()
        (occupied_lost_found / "lost+found").mkdir()
        (occupied_lost_found / "lost+found" / "keep").write_text("safe")
        result = run(good, occupied_lost_found)
        assert result.returncode != 0
        assert (occupied_lost_found / "lost+found" / "keep").read_text() == "safe"

        linked_target = root / "linked-target"
        linked_target.mkdir()
        linked_destination = root / "linked-destination"
        linked_destination.symlink_to(linked_target, target_is_directory=True)
        result = run(good, linked_destination)
        assert result.returncode != 0
        assert list(linked_target.iterdir()) == []

        # A real destination below a symlinked parent must also be rejected.
        real_parent = root / "real-parent"
        real_parent.mkdir()
        linked_parent = root / "linked-parent"
        linked_parent.symlink_to(real_parent, target_is_directory=True)
        nested_destination = linked_parent / "nested-stage"
        result = run(good, nested_destination)
        assert result.returncode != 0
        assert not (real_parent / "nested-stage").exists()

        bad = root / "bad.tar"
        make_tar(bad, [("../escape", b"x"), ("etc/os-release", b"x"),
                       ("sbin/init", b"x"), ("bin/busybox", b"x")])
        result = run(bad, root / "bad-stage")
        assert result.returncode != 0
        assert not (root / "escape").exists()

        windows_path = root / "windows-path.tar"
        make_tar(windows_path, [("etc/os-release", b"x"), ("sbin/init", b"x"),
                                ("bin/busybox", b"x"), ("..\\escape", b"x")])
        result = run(windows_path, root / "windows-path-stage")
        assert result.returncode != 0

        duplicate = root / "duplicate.tar"
        make_tar(duplicate, [("etc/os-release", b"x"), ("sbin/init", b"x"),
                             ("bin/busybox", b"x"), ("./etc/os-release", b"overwrite")])
        result = run(duplicate, root / "duplicate-stage")
        assert result.returncode != 0

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

        bad_windows_link = root / "bad-windows-link.tar"
        with tarfile.open(bad_windows_link, "w") as tar:
            for name, data in (("etc/os-release", b"x"), ("sbin/init", b"x"),
                               ("bin/busybox", b"x")):
                info = tarfile.TarInfo(name)
                info.size = len(data)
                tar.addfile(info, io.BytesIO(data))
            link = tarfile.TarInfo("etc/windows-escape")
            link.type = tarfile.SYMTYPE
            link.linkname = "..\\outside"
            tar.addfile(link)
        result = run(bad_windows_link, root / "bad-windows-link-stage")
        assert result.returncode != 0

        incomplete = root / "incomplete.tar"
        make_tar(incomplete, [("etc/os-release", b"x")])
        result = run(incomplete, root / "incomplete-stage")
        assert result.returncode != 0
    print("rootfs staging safety tests: PASS")


if __name__ == "__main__":
    main()
