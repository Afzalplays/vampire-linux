#!/usr/bin/env python3
"""Regression tests for safe Vampire OS rootfs archive staging."""
import importlib.util
import io
import pathlib
import tarfile
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("stage_rootfs", ROOT / "scripts" / "stage-rootfs.py")
STAGE_ROOTFS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(STAGE_ROOTFS)
validate = STAGE_ROOTFS.validate


def archive_with(entries):
    handle = tempfile.NamedTemporaryFile(suffix=".tar", delete=False)
    handle.close()
    path = pathlib.Path(handle.name)
    with tarfile.open(path, "w") as tar:
        for name, kind, target in entries:
            info = tarfile.TarInfo(name)
            if kind == "dir":
                info.type = tarfile.DIRTYPE
                tar.addfile(info)
            elif kind == "symlink":
                info.type = tarfile.SYMTYPE
                info.linkname = target
                tar.addfile(info)
            elif kind == "file":
                data = b"x"
                info.size = len(data)
                tar.addfile(info, io.BytesIO(data))
    return path


class RootfsArchivePathTests(unittest.TestCase):
    def make_entries(self, extra):
        base = [
            ("etc", "dir", ""),
            ("etc/os-release", "file", ""),
            ("sbin", "dir", ""),
            ("sbin/init", "file", ""),
            ("bin", "dir", ""),
            ("bin/busybox", "file", ""),
        ]
        return base + extra

    def test_rejects_child_beneath_symlink(self):
        path = archive_with(self.make_entries([
            ("opt", "symlink", "etc"),
            ("opt/payload", "file", ""),
        ]))
        self.addCleanup(path.unlink)
        with self.assertRaisesRegex(ValueError, "ancestor that is not a directory"):
            validate(path)

    def test_rejects_child_beneath_regular_file(self):
        path = archive_with(self.make_entries([
            ("opt", "file", ""),
            ("opt/payload", "file", ""),
        ]))
        self.addCleanup(path.unlink)
        with self.assertRaisesRegex(ValueError, "ancestor that is not a directory"):
            validate(path)

    def test_accepts_normal_directory_tree(self):
        path = archive_with(self.make_entries([
            ("usr", "dir", ""),
            ("usr/bin", "dir", ""),
            ("usr/bin/example", "file", ""),
        ]))
        self.addCleanup(path.unlink)
        self.assertGreater(validate(path), 0)


    def test_rejects_duplicate_normalized_entries(self):
        path = archive_with(self.make_entries([
            ("usr", "dir", ""),
            ("usr/", "dir", ""),
        ]))
        self.addCleanup(path.unlink)
        with self.assertRaisesRegex(ValueError, "duplicate archive path"):
            validate(path)

    def test_rejects_escaping_symbolic_link(self):
        path = archive_with(self.make_entries([
            ("opt", "dir", ""),
            ("opt/escape", "symlink", "../../../outside"),
        ]))
        self.addCleanup(path.unlink)
        with self.assertRaisesRegex(ValueError, "link escapes rootfs"):
            validate(path)

    def test_accepts_absolute_rootfs_symlink_and_rewrites_relative(self):
        path = archive_with(self.make_entries([
            ("usr", "dir", ""),
            ("usr/bin", "dir", ""),
            ("usr/bin/sh", "symlink", "/bin/busybox"),
        ]))
        self.addCleanup(path.unlink)
        with tarfile.open(path, "r") as tar:
            member = next(item for item in tar.getmembers() if item.name == "usr/bin/sh")
            STAGE_ROOTFS.sanitize_member(member)
            self.assertEqual(member.linkname, "../../bin/busybox")


if __name__ == "__main__":
    unittest.main()
