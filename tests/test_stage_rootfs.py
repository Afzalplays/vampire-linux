#!/usr/bin/env python3
"""Security regression tests for safe rootfs archive staging."""
import importlib.util
import io
import pathlib
import tarfile
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "scripts" / "stage-rootfs.py"
SPEC = importlib.util.spec_from_file_location("stage_rootfs", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def make_archive(path, entries):
    with tarfile.open(path, "w") as archive:
        for name, kind, target in entries:
            info = tarfile.TarInfo(name)
            if kind == "dir":
                info.type = tarfile.DIRTYPE
                archive.addfile(info)
            elif kind == "symlink":
                info.type = tarfile.SYMTYPE
                info.linkname = target
                archive.addfile(info)
            else:
                data = target if isinstance(target, bytes) else target.encode()
                info.size = len(data)
                archive.addfile(info, io.BytesIO(data))


class RootfsArchiveTests(unittest.TestCase):
    def valid_entries(self):
        return [
            ("etc", "dir", ""),
            ("etc/os-release", "file", "NAME=Vampire OS\n"),
            ("sbin", "dir", ""),
            ("sbin/init", "file", b"init"),
            ("bin", "dir", ""),
            ("bin/busybox", "file", b"busybox"),
        ]

    def test_valid_rootfs_archive_passes_validation(self):
        with tempfile.TemporaryDirectory() as temp:
            archive = pathlib.Path(temp) / "rootfs.tar"
            make_archive(archive, self.valid_entries())
            self.assertEqual(MODULE.validate(archive), 6)

    def test_rejects_parent_traversal(self):
        with tempfile.TemporaryDirectory() as temp:
            archive = pathlib.Path(temp) / "rootfs.tar"
            make_archive(archive, self.valid_entries() + [("../escape", "file", "bad")])
            with self.assertRaisesRegex(ValueError, "unsafe archive path"):
                MODULE.validate(archive)

    def test_rejects_duplicate_archive_paths(self):
        with tempfile.TemporaryDirectory() as temp:
            archive = pathlib.Path(temp) / "rootfs.tar"
            entries = self.valid_entries() + [("etc/os-release", "file", "overwritten")]
            make_archive(archive, entries)
            with self.assertRaisesRegex(ValueError, "duplicate archive path"):
                MODULE.validate(archive)

    def test_rejects_symlink_that_escapes_root(self):
        with tempfile.TemporaryDirectory() as temp:
            archive = pathlib.Path(temp) / "rootfs.tar"
            entries = self.valid_entries() + [("etc/escape", "symlink", "../../../outside")]
            make_archive(archive, entries)
            with self.assertRaisesRegex(ValueError, "link escapes rootfs"):
                MODULE.validate(archive)

    def test_rejects_missing_required_init(self):
        with tempfile.TemporaryDirectory() as temp:
            archive = pathlib.Path(temp) / "rootfs.tar"
            entries = [entry for entry in self.valid_entries() if entry[0] != "sbin/init"]
            make_archive(archive, entries)
            with self.assertRaisesRegex(ValueError, "missing required paths"):
                MODULE.validate(archive)

    def test_stage_refuses_nonempty_destination_without_modifying_it(self):
        with tempfile.TemporaryDirectory() as temp:
            archive = pathlib.Path(temp) / "rootfs.tar"
            destination = pathlib.Path(temp) / "target"
            destination.mkdir()
            sentinel = destination / "keep.txt"
            sentinel.write_text("preserve")
            make_archive(archive, self.valid_entries())
            with self.assertRaisesRegex(ValueError, "destination must be new"):
                MODULE.stage(archive, destination)
            self.assertEqual(sentinel.read_text(), "preserve")


if __name__ == "__main__":
    unittest.main(verbosity=2)
