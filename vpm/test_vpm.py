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
    def test_reject_https_downgrade_redirect(self):
        from unittest.mock import patch

        class RedirectedResponse:
            status = 200
            def __enter__(self): return self
            def __exit__(self, *args): return False
            def geturl(self): return "http://mirror.example.invalid/package.tar.gz"
            def read(self, size=-1): return b"package"

        with tempfile.TemporaryDirectory() as tmp:
            destination = pathlib.Path(tmp) / "package.tar.gz"
            with patch.object(vpm.urllib.request, "urlopen", return_value=RedirectedResponse()):
                with self.assertRaises(SystemExit):
                    vpm.fetch("https://repo.example.invalid/package.tar.gz", destination, 1024)
            self.assertFalse(destination.exists())

    def test_failed_download_preserves_existing_cache_file(self):
        from unittest.mock import patch

        class InterruptedResponse:
            status = 200
            def __init__(self): self.calls = 0
            def __enter__(self): return self
            def __exit__(self, *args): return False
            def geturl(self): return "https://repo.example.invalid/package.tar.gz"
            def read(self, size=-1):
                self.calls += 1
                if self.calls == 1: return b"partial"
                raise OSError("simulated network interruption")

        with tempfile.TemporaryDirectory() as tmp:
            destination = pathlib.Path(tmp) / "cached.tar.gz"
            destination.write_bytes(b"previous verified cache")
            with patch.object(vpm.urllib.request, "urlopen", return_value=InterruptedResponse()):
                with self.assertRaises(SystemExit):
                    vpm.fetch("https://repo.example.invalid/package.tar.gz", destination, 1024)
            self.assertEqual(destination.read_bytes(), b"previous verified cache")
            self.assertEqual(list(pathlib.Path(tmp).glob(".cached.tar.gz.*.download")), [])

    def test_validate_package_index_entry(self):
        valid = {
            "name": "hello-vampire",
            "version": "1.0.0",
            "url": "packages/hello-vampire.tar.gz",
            "sha256": "a" * 64,
            "depends": [],
            "architecture": "any",
        }
        self.assertEqual(
            vpm.validate_package_entry(valid, "https://repo.example.invalid/")["name"],
            "hello-vampire")

    def test_reject_package_cache_path_traversal(self):
        invalid = {
            "name": "../outside",
            "version": "1.0.0",
            "url": "packages/outside.tar.gz",
            "sha256": "a" * 64,
            "depends": [],
        }
        with self.assertRaises(ValueError):
            vpm.validate_package_entry(invalid, "https://repo.example.invalid/")

    def test_reject_malformed_package_digest_and_dependencies(self):
        invalid = {
            "name": "hello-vampire",
            "version": "1.0.0",
            "url": "packages/hello-vampire.tar.gz",
            "sha256": "not-a-digest",
            "depends": "python",
        }
        with self.assertRaises(ValueError):
            vpm.validate_package_entry(invalid, "https://repo.example.invalid/")

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

    def test_partial_extraction_rolls_back_created_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            archive = base / "partial.tar.gz"
            root = base / "root"
            root.mkdir()
            (root / "already.txt").write_text("keep existing")
            with tarfile.open(archive, "w:gz") as tf:
                first = b"new file"
                info = tarfile.TarInfo("new.txt")
                info.size = len(first)
                tf.addfile(info, io.BytesIO(first))
                second = b"must not overwrite"
                info = tarfile.TarInfo("already.txt")
                info.size = len(second)
                tf.addfile(info, io.BytesIO(second))
            with self.assertRaises(FileExistsError):
                vpm.safe_extract(archive, root)
            self.assertFalse((root / "new.txt").exists())
            self.assertEqual((root / "already.txt").read_text(), "keep existing")

    def test_partial_extraction_rolls_back_explicit_nested_directories(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            archive = base / "partial-directory.tar.gz"
            root = base / "root"
            root.mkdir()
            (root / "already.txt").write_text("keep")
            with tarfile.open(archive, "w:gz") as tf:
                directory = tarfile.TarInfo("new-parent/new-child")
                directory.type = tarfile.DIRTYPE
                tf.addfile(directory)
                data = b"collision"
                info = tarfile.TarInfo("already.txt")
                info.size = len(data)
                tf.addfile(info, io.BytesIO(data))
            with self.assertRaises(FileExistsError):
                vpm.safe_extract(archive, root)
            self.assertFalse((root / "new-parent").exists())
            self.assertEqual((root / "already.txt").read_text(), "keep")

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

    def test_multi_package_rollback_removes_only_extracted_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp) / "root"
            root.mkdir()
            owned = root / "usr/share/new-package.txt"
            owned.parent.mkdir(parents=True)
            owned.write_text("new package")
            keep = root / "usr/share/keep.txt"
            keep.write_text("keep")
            link = root / "usr/share/link.txt"
            link.symlink_to(keep)
            failures = vpm.rollback_extracted(
                root, [["usr/share/new-package.txt", "usr/share/link.txt"]])
            self.assertEqual(failures, ["usr/share/link.txt"])
            self.assertFalse(owned.exists())
            self.assertEqual(keep.read_text(), "keep")
            self.assertTrue(link.is_symlink())

    def test_installed_database_write_ignores_predictable_temp_symlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            db_path = base / "installed.json"
            outside = base / "outside.txt"
            outside.write_text("must remain")
            db_path.with_suffix(".tmp").symlink_to(outside)
            old_db = vpm.DB
            try:
                vpm.DB = db_path
                vpm.write_installed_db({"sample": {"version": "1.0", "files": []}})
            finally:
                vpm.DB = old_db
            self.assertEqual(outside.read_text(), "must remain")
            self.assertTrue(db_path.with_suffix(".tmp").is_symlink())
            self.assertEqual(__import__("json").loads(db_path.read_text())["sample"]["version"], "1.0")
            self.assertEqual(db_path.stat().st_mode & 0o777, 0o600)

    def test_remove_restores_files_if_database_commit_fails(self):
        from types import SimpleNamespace
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            root = base / "root"
            root.mkdir()
            owned = root / "usr/share/owned.txt"
            owned.parent.mkdir(parents=True)
            owned.write_text("owned data")
            db_path = base / "installed.json"
            db_path.write_text('{"sample": {"version": "1.0", "files": ["usr/share/owned.txt"]}}')
            old_root, old_db = vpm.ROOT, vpm.DB
            original_replace = vpm.os.replace
            def fail_database_replace(src, dst):
                if pathlib.Path(dst) == db_path:
                    raise OSError("simulated database commit failure")
                return original_replace(src, dst)
            try:
                vpm.ROOT, vpm.DB = root, db_path
                with patch.object(vpm.os, "replace", side_effect=fail_database_replace):
                    with self.assertRaises(OSError):
                        vpm.command_remove(SimpleNamespace(name="sample"))
            finally:
                vpm.ROOT, vpm.DB = old_root, old_db
            self.assertEqual(owned.read_text(), "owned data")
            self.assertIn("sample", __import__("json").loads(db_path.read_text()))
            self.assertEqual(list(owned.parent.glob(".vpm-remove-*")), [])

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

    def test_remove_refuses_final_symlink_without_touching_target(self):
        from types import SimpleNamespace
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            root = base / "root"
            root.mkdir()
            target = root / "usr/share/keep.txt"
            target.parent.mkdir(parents=True)
            target.write_text("keep")
            link = root / "usr/share/owned-link.txt"
            link.symlink_to(target)
            db_path = base / "installed.json"
            db_path.write_text('{"sample": {"version": "1.0", "files": ["usr/share/owned-link.txt"]}}')
            old_root, old_db = vpm.ROOT, vpm.DB
            try:
                vpm.ROOT, vpm.DB = root, db_path
                with self.assertRaises(SystemExit):
                    vpm.command_remove(SimpleNamespace(name="sample"))
            finally:
                vpm.ROOT, vpm.DB = old_root, old_db
            self.assertEqual(target.read_text(), "keep")
            self.assertTrue(link.is_symlink())
            self.assertIn("sample", __import__("json").loads(db_path.read_text()))

    def test_remove_preflights_all_paths_before_deleting(self):
        from types import SimpleNamespace
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            root = base / "root"
            root.mkdir()
            owned = root / "usr/share/owned.txt"
            owned.parent.mkdir(parents=True)
            owned.write_text("must remain when manifest is unsafe")
            target = root / "usr/share/keep.txt"
            target.write_text("keep")
            (root / "usr/share/unsafe-link").symlink_to(target)
            db_path = base / "installed.json"
            db_path.write_text('{"sample": {"version": "1.0", "files": ["usr/share/owned.txt", "usr/share/unsafe-link"]}}')
            old_root, old_db = vpm.ROOT, vpm.DB
            try:
                vpm.ROOT, vpm.DB = root, db_path
                with self.assertRaises(SystemExit):
                    vpm.command_remove(SimpleNamespace(name="sample"))
            finally:
                vpm.ROOT, vpm.DB = old_root, old_db
            self.assertEqual(owned.read_text(), "must remain when manifest is unsafe")
            self.assertEqual(target.read_text(), "keep")
            self.assertIn("sample", __import__("json").loads(db_path.read_text()))

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


    def test_extract_rejects_symlinked_destination_ancestor(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            real_parent = base / "real"
            real_parent.mkdir()
            linked_parent = base / "linked"
            linked_parent.symlink_to(real_parent, target_is_directory=True)
            destination = linked_parent / "root"
            archive = base / "package.tar.gz"
            with tarfile.open(archive, "w:gz") as tf:
                payload = b"must not be written"
                info = tarfile.TarInfo("usr/share/payload")
                info.size = len(payload)
                tf.addfile(info, io.BytesIO(payload))
            with self.assertRaises(SystemExit):
                vpm.safe_extract(archive, destination)
            self.assertFalse((real_parent / "root").exists())

    def test_installed_database_rejects_symlinked_parent(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            real_parent = base / "real"
            real_parent.mkdir()
            linked_parent = base / "linked"
            linked_parent.symlink_to(real_parent, target_is_directory=True)
            old_db = vpm.DB
            try:
                vpm.DB = linked_parent / "installed.json"
                with self.assertRaises(SystemExit):
                    vpm.write_installed_db({"sample": {"version": "1"}})
            finally:
                vpm.DB = old_db
            self.assertFalse((real_parent / "installed.json").exists())

    def test_config_rejects_symlinked_parent(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            real_parent = base / "real"
            real_parent.mkdir()
            linked_parent = base / "linked"
            linked_parent.symlink_to(real_parent, target_is_directory=True)
            old_config = vpm.CONFIG
            try:
                vpm.CONFIG = linked_parent / "vpm.json"
                with self.assertRaises(SystemExit):
                    vpm.load_config()
            finally:
                vpm.CONFIG = old_config
            self.assertFalse((real_parent / "vpm.json").exists())


    def test_download_rejects_symlinked_parent_directory(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            real = base / "real"
            real.mkdir()
            linked = base / "linked"
            linked.symlink_to(real, target_is_directory=True)
            destination = linked / "index.json"
            with patch.object(vpm.urllib.request, "urlopen") as urlopen:
                with self.assertRaises(SystemExit):
                    vpm.fetch("https://repo.example.invalid/index.json", destination, 1024)
                urlopen.assert_not_called()
            self.assertFalse((real / "index.json").exists())

    def test_installed_database_read_rejects_symlinked_parent(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            real = base / "real"
            real.mkdir()
            linked = base / "linked"
            linked.symlink_to(real, target_is_directory=True)
            old_db = vpm.DB
            try:
                vpm.DB = linked / "installed.json"
                with self.assertRaises(SystemExit):
                    vpm.installed_db()
            finally:
                vpm.DB = old_db
            self.assertFalse((real / "installed.json").exists())

    def test_cache_index_rejects_symlinked_cache_directory(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            real = base / "real"
            real.mkdir()
            linked = base / "linked"
            linked.symlink_to(real, target_is_directory=True)
            old_cache = vpm.CACHE
            try:
                vpm.CACHE = linked
                with patch.object(vpm, "load_config", return_value={"repositories": []}):
                    with self.assertRaises(SystemExit):
                        vpm.load_index()
            finally:
                vpm.CACHE = old_cache
            self.assertEqual(list(real.iterdir()), [])

if __name__ == "__main__":
    unittest.main()
