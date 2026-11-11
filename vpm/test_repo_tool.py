import importlib.util
import json
import pathlib
import tempfile
import unittest

TOOL = pathlib.Path(__file__).with_name("repo_tool.py")
SPEC = importlib.util.spec_from_file_location("vpm_repo_tool", TOOL)
repo_tool = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(repo_tool)


class RepositoryBuilderTests(unittest.TestCase):
    def test_build_index_copies_archive_and_hashes_it(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            archive = base / "hello.tar.gz"
            archive.write_bytes(b"example package bytes")
            metadata = base / "hello.json"
            metadata.write_text(json.dumps({
                "name": "hello-vampire",
                "version": "0.1.0",
                "description": "Hello from Vampire OS",
                "architecture": "any",
                "license": "MIT",
                "depends": [],
                "archive": str(archive),
            }))
            output = base / "repo"
            index = repo_tool.build_index("vampire-testing", "x86_64", [metadata], output)
            package = index["packages"][0]
            self.assertEqual(package["name"], "hello-vampire")
            self.assertEqual(package["url"], "packages/hello-vampire-0.1.0.tar.gz")
            self.assertEqual(package["sha256"], repo_tool.sha256_file(output / package["url"]))
            self.assertTrue((output / "index.json").is_file())

    def test_reject_duplicate_package_names(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            archive = base / "pkg.tar.gz"
            archive.write_bytes(b"pkg")
            meta = {
                "name": "same-package", "version": "1.0", "description": "test",
                "architecture": "any", "license": "MIT", "depends": [], "archive": str(archive)
            }
            paths = []
            for n in ("a.json", "b.json"):
                p = base / n
                p.write_text(json.dumps(meta))
                paths.append(p)
            with self.assertRaises(ValueError):
                repo_tool.build_index("vampire-testing", "x86_64", paths, base / "out")

    def test_reject_invalid_package_name(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            archive = base / "pkg.tar.gz"
            archive.write_bytes(b"pkg")
            meta = base / "bad.json"
            meta.write_text(json.dumps({
                "name": "../escape", "version": "1.0", "description": "test",
                "architecture": "any", "license": "MIT", "depends": [], "archive": str(archive)
            }))
            with self.assertRaises(ValueError):
                repo_tool.load_package_metadata(meta)


if __name__ == "__main__":
    unittest.main()
