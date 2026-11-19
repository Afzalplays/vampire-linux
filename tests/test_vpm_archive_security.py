#!/usr/bin/env python3
"""Security regression tests for the experimental VPM archive extractor."""
import importlib.util
import io
import pathlib
import tarfile
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("vpm_client", ROOT / "vpm" / "vpm")
VPM = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VPM)


def make_archive(path, members):
    with tarfile.open(path, "w:gz") as archive:
        for name, kind, payload in members:
            info = tarfile.TarInfo(name)
            if kind == "dir":
                info.type = tarfile.DIRTYPE
                archive.addfile(info)
            elif kind == "symlink":
                info.type = tarfile.SYMTYPE
                info.linkname = payload
                archive.addfile(info)
            elif kind == "file":
                data = payload if isinstance(payload, bytes) else payload.encode()
                info.size = len(data)
                archive.addfile(info, io.BytesIO(data))


class VpmArchiveSecurityTests(unittest.TestCase):
    def test_extracts_regular_file_and_records_manifest(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp) / "root"
            root.mkdir()
            archive = pathlib.Path(temp) / "good.tar.gz"
            make_archive(archive, [("usr", "dir", ""), ("usr/bin", "dir", ""),
                                   ("usr/bin/hello", "file", "hello")])
            files = VPM.safe_extract(archive, root)
            self.assertEqual(files, ["usr/bin/hello"])
            self.assertEqual((root / "usr/bin/hello").read_text(), "hello")

    def test_rejects_parent_traversal(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp) / "root"
            root.mkdir()
            archive = pathlib.Path(temp) / "bad.tar.gz"
            make_archive(archive, [("../outside", "file", "bad")])
            with self.assertRaises(SystemExit):
                VPM.safe_extract(archive, root)
            self.assertFalse((pathlib.Path(temp) / "outside").exists())

    def test_rejects_absolute_paths(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp) / "root"
            root.mkdir()
            archive = pathlib.Path(temp) / "bad.tar.gz"
            make_archive(archive, [("/tmp/vpm-outside", "file", "bad")])
            with self.assertRaises(SystemExit):
                VPM.safe_extract(archive, root)

    def test_rejects_symlink_entries(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp) / "root"
            root.mkdir()
            archive = pathlib.Path(temp) / "bad.tar.gz"
            make_archive(archive, [("link", "symlink", "../../outside")])
            with self.assertRaises(SystemExit):
                VPM.safe_extract(archive, root)
            self.assertFalse((pathlib.Path(temp) / "outside").exists())

    def test_rejects_duplicate_entries(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp) / "root"
            root.mkdir()
            archive = pathlib.Path(temp) / "bad.tar.gz"
            make_archive(archive, [("usr", "dir", ""), ("usr/", "dir", "")])
            with self.assertRaises(SystemExit):
                VPM.safe_extract(archive, root)

    def test_does_not_overwrite_existing_files(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp) / "root"
            (root / "usr/bin").mkdir(parents=True)
            existing = root / "usr/bin/tool"
            existing.write_text("user data")
            archive = pathlib.Path(temp) / "package.tar.gz"
            make_archive(archive, [("usr/bin/tool", "file", "package data")])
            with self.assertRaises(FileExistsError):
                VPM.safe_extract(archive, root)
            self.assertEqual(existing.read_text(), "user data")

    def test_rejects_symlinked_extraction_root(self):
        with tempfile.TemporaryDirectory() as temp:
            real = pathlib.Path(temp) / "real"
            real.mkdir()
            alias = pathlib.Path(temp) / "alias"
            alias.symlink_to(real, target_is_directory=True)
            archive = pathlib.Path(temp) / "good.tar.gz"
            make_archive(archive, [("file", "file", "data")])
            with self.assertRaises(SystemExit):
                VPM.safe_extract(archive, alias)


    def test_rolls_back_new_files_after_later_write_failure(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp) / "root"
            (root / "usr/bin").mkdir(parents=True)
            existing = root / "usr/bin/existing"
            existing.write_text("preserve")
            archive = pathlib.Path(temp) / "partial.tar.gz"
            make_archive(archive, [
                ("usr/bin/new-file", "file", "temporary"),
                ("usr/bin/existing", "file", "replacement"),
            ])
            with self.assertRaises(FileExistsError):
                VPM.safe_extract(archive, root)
            self.assertFalse((root / "usr/bin/new-file").exists())
            self.assertEqual(existing.read_text(), "preserve")


if __name__ == "__main__":
    unittest.main(verbosity=2)
