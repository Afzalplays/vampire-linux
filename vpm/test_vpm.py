import importlib.machinery
import importlib.util
import io
import pathlib
import tarfile
import tempfile
import unittest

VPM_PATH = pathlib.Path(__file__).with_name("vpm")
LOADER = importlib.machinery.SourceFileLoader("vpm", str(VPM_PATH))
SPEC = importlib.util.spec_from_loader("vpm", LOADER)
vpm = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(vpm)

class ArchiveSafetyTests(unittest.TestCase):
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

if __name__ == "__main__":
    unittest.main()
