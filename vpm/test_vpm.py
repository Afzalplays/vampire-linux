import importlib.machinery
import importlib.util
import io
import pathlib
import subprocess
import sys
import tarfile
import tempfile
import unittest

VPM_PATH = pathlib.Path(__file__).with_name("vpm")
LOADER = importlib.machinery.SourceFileLoader("vpm", str(VPM_PATH))
SPEC = importlib.util.spec_from_loader("vpm", LOADER)
vpm = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(vpm)

class ArchiveSafetyTests(unittest.TestCase):
    def test_install_accepts_yes_flag(self):
        result = subprocess.run(
            [sys.executable, str(VPM_PATH), "install", "--help"],
            capture_output=True, text=True, check=True)
        self.assertIn("-y, --yes", result.stdout)


    def test_extract_regular_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = pathlib.Path(tmp) / "ok.tar.gz"
            root = pathlib.Path(tmp) / "root"
            root.mkdir()
            with tarfile.open(archive, "w:gz") as tf:
                data = b"hello vampire"
                info = tarfile.TarInfo("usr/share/hello.txt")
                info.size = len(data)
                tf.addfile(info, io.BytesIO(data))
            vpm.safe_extract(archive, root)
            self.assertEqual((root / "usr/share/hello.txt").read_bytes(), b"hello vampire")

    def test_reject_parent_traversal(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = pathlib.Path(tmp) / "bad.tar.gz"
            root = pathlib.Path(tmp) / "root"
            root.mkdir()
            with tarfile.open(archive, "w:gz") as tf:
                data = b"escape"
                info = tarfile.TarInfo("../escape.txt")
                info.size = len(data)
                tf.addfile(info, io.BytesIO(data))
            with self.assertRaises(SystemExit):
                vpm.safe_extract(archive, root)
            self.assertFalse((pathlib.Path(tmp) / "escape.txt").exists())

    def test_reject_symlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = pathlib.Path(tmp) / "link.tar.gz"
            root = pathlib.Path(tmp) / "root"
            root.mkdir()
            with tarfile.open(archive, "w:gz") as tf:
                info = tarfile.TarInfo("link")
                info.type = tarfile.SYMTYPE
                info.linkname = "/etc/passwd"
                tf.addfile(info)
            with self.assertRaises(SystemExit):
                vpm.safe_extract(archive, root)


    def test_extract_returns_owned_file_manifest(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = pathlib.Path(tmp) / "owned.tar.gz"
            root = pathlib.Path(tmp) / "root"
            root.mkdir()
            with tarfile.open(archive, "w:gz") as tf:
                data = b"owned"
                info = tarfile.TarInfo("usr/share/owned.txt")
                info.size = len(data)
                tf.addfile(info, io.BytesIO(data))
            self.assertEqual(vpm.safe_extract(archive, root), ["usr/share/owned.txt"])

    def test_remove_deletes_only_recorded_package_files(self):
        from types import SimpleNamespace
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            root = base / "root"
            root.mkdir()
            owned = root / "usr/share/owned.txt"
            unrelated = root / "usr/share/unrelated.txt"
            owned.parent.mkdir(parents=True)
            owned.write_text("owned")
            unrelated.write_text("keep")
            db_path = base / "installed.json"
            db_path.write_text('{"sample": {"version": "1.0", "files": ["usr/share/owned.txt"]}}')
            old_root, old_db = vpm.ROOT, vpm.DB
            try:
                vpm.ROOT, vpm.DB = root, db_path
                vpm.command_remove(SimpleNamespace(name="sample"))
            finally:
                vpm.ROOT, vpm.DB = old_root, old_db
            self.assertFalse(owned.exists())
            self.assertTrue(unrelated.exists())
            self.assertNotIn("sample", __import__("json").loads(db_path.read_text()))

    def test_remove_refuses_untracked_legacy_record(self):
        from types import SimpleNamespace
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            root = base / "root"
            root.mkdir()
            db_path = base / "installed.json"
            db_path.write_text('{"legacy": {"version": "0.1", "files": "not-yet-tracked"}}')
            old_root, old_db = vpm.ROOT, vpm.DB
            try:
                vpm.ROOT, vpm.DB = root, db_path
                with self.assertRaises(SystemExit):
                    vpm.command_remove(SimpleNamespace(name="legacy"))
            finally:
                vpm.ROOT, vpm.DB = old_root, old_db

if __name__ == "__main__":
    unittest.main()
