import importlib.util, pathlib, unittest
MODULE=pathlib.Path(__file__).with_name("update_client.py")
SPEC=importlib.util.spec_from_file_location("vupdate",MODULE)
vupdate=importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(vupdate)
class UpdateManifestTests(unittest.TestCase):
    def manifest(self):
        return {"format":1,"channel":"stable","architecture":"x86_64","version":"0.2.0",
                "artifact":{"url":"https://updates.example.invalid/vampire.iso","sha256":"a"*64,"size":1024}}
    def test_reject_artifact_https_downgrade_redirect(self):
        import tempfile
        from unittest.mock import patch

        class RedirectedResponse:
            status = 200
            def __enter__(self): return self
            def __exit__(self, *args): return False
            def geturl(self): return "http://mirror.example.invalid/vampire.iso"
            def read(self, size=-1): return b"image"

        manifest = self.manifest()
        with tempfile.TemporaryDirectory() as tmp:
            with patch.object(vupdate, "CACHE", pathlib.Path(tmp)), \
                 patch.object(vupdate, "verified_manifest", return_value=manifest), \
                 patch.object(vupdate.urllib.request, "urlopen", return_value=RedirectedResponse()):
                with self.assertRaises(SystemExit):
                    vupdate.command_download(None)
            self.assertEqual(list(pathlib.Path(tmp).iterdir()), [])

    def test_reject_https_downgrade_redirect(self):
        import tempfile
        from unittest.mock import patch

        class RedirectedResponse:
            status = 200
            def __enter__(self): return self
            def __exit__(self, *args): return False
            def geturl(self): return "http://mirror.example.invalid/manifest.json"
            def read(self, size=-1): return b"{}"

        with patch.object(vupdate.urllib.request, "urlopen", return_value=RedirectedResponse()):
            with self.assertRaises(SystemExit):
                vupdate.fetch_bytes("https://updates.example.invalid/manifest.json", 1024)

    def test_verify_staged_image_against_signed_manifest(self):
        import hashlib
        import tempfile
        from types import SimpleNamespace
        from unittest.mock import patch

        payload = b"vampire-os-image"
        manifest = self.manifest()
        manifest["artifact"]["size"] = len(payload)
        manifest["artifact"]["sha256"] = hashlib.sha256(payload).hexdigest()
        with tempfile.TemporaryDirectory() as tmp:
            cache = pathlib.Path(tmp)
            staged = cache / "vampire-os-0.2.0-x86_64.img"
            staged.write_bytes(payload)
            with patch.object(vupdate, "CACHE", cache), patch.object(
                    vupdate, "verified_manifest", return_value=manifest):
                vupdate.command_verify(SimpleNamespace(file=None))

    def test_verify_rejects_staged_image_hash_mismatch(self):
        import tempfile
        from types import SimpleNamespace
        from unittest.mock import patch

        manifest = self.manifest()
        manifest["artifact"]["size"] = 5
        with tempfile.TemporaryDirectory() as tmp:
            staged = pathlib.Path(tmp) / "wrong.img"
            staged.write_bytes(b"wrong")
            with patch.object(vupdate, "verified_manifest", return_value=manifest):
                with self.assertRaises(SystemExit):
                    vupdate.command_verify(SimpleNamespace(file=str(staged)))

    def test_verify_rejects_staged_image_size_mismatch(self):
        import tempfile
        from types import SimpleNamespace
        from unittest.mock import patch

        manifest = self.manifest()
        with tempfile.TemporaryDirectory() as tmp:
            staged = pathlib.Path(tmp) / "short.img"
            staged.write_bytes(b"short")
            with patch.object(vupdate, "verified_manifest", return_value=manifest):
                with self.assertRaises(SystemExit):
                    vupdate.command_verify(SimpleNamespace(file=str(staged)))

    def test_verify_rejects_missing_staged_image(self):
        import tempfile
        from types import SimpleNamespace
        from unittest.mock import patch

        with tempfile.TemporaryDirectory() as tmp:
            with patch.object(vupdate, "CACHE", pathlib.Path(tmp)), patch.object(
                    vupdate, "verified_manifest", return_value=self.manifest()):
                with self.assertRaises(SystemExit):
                    vupdate.command_verify(SimpleNamespace(file=None))

    def test_valid_manifest(self):
        self.assertEqual(vupdate.validate_manifest(self.manifest())["version"],"0.2.0")
    def test_reject_http_artifact(self):
        data=self.manifest(); data["artifact"]["url"]="http://updates.example.invalid/a"
        with self.assertRaises(ValueError): vupdate.validate_manifest(data)
    def test_reject_wrong_architecture(self):
        data=self.manifest(); data["architecture"]="aarch64"
        with self.assertRaises(ValueError): vupdate.validate_manifest(data)
    def test_reject_bad_hash(self):
        data=self.manifest(); data["artifact"]["sha256"]="bad"
        with self.assertRaises(ValueError): vupdate.validate_manifest(data)
    def test_reject_oversized_artifact(self):
        data=self.manifest(); data["artifact"]["size"]=vupdate.MAX_ARTIFACT+1
        with self.assertRaises(ValueError): vupdate.validate_manifest(data)
    def test_reject_channel_mismatch(self):
        with self.assertRaises(ValueError): vupdate.validate_manifest(self.manifest(),channel="testing")

    def test_read_config_rejects_symlink(self):
        import json
        import tempfile
        from unittest.mock import patch

        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            target = root / "real-config.json"
            target.write_text(json.dumps({
                "manifest_url": "https://updates.example.invalid/manifest.json",
                "signature_url": "https://updates.example.invalid/manifest.minisig",
                "minisign_public_key": "trusted-key",
            }))
            link = root / "update.json"
            link.symlink_to(target)
            with patch.object(vupdate, "CONFIG", link):
                with self.assertRaises(SystemExit):
                    vupdate.read_config()

    def test_verified_manifest_rejects_symlinked_cache_before_network(self):
        import tempfile
        from unittest.mock import patch

        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            target = root / "real-cache"
            target.mkdir()
            link = root / "cache-link"
            link.symlink_to(target, target_is_directory=True)
            with patch.object(vupdate, "CACHE", link), patch.object(
                    vupdate, "read_config", return_value={
                        "manifest_url": "https://updates.example.invalid/manifest.json",
                        "signature_url": "https://updates.example.invalid/manifest.minisig",
                        "minisign_public_key": "trusted-key",
                    }), patch.object(vupdate.shutil, "which") as which:
                with self.assertRaises(SystemExit):
                    vupdate.verified_manifest()
                which.assert_not_called()

    def test_status_rejects_symlinked_cache(self):
        import tempfile
        from unittest.mock import patch

        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            target = root / "real-cache"
            target.mkdir()
            link = root / "cache-link"
            link.symlink_to(target, target_is_directory=True)
            with patch.object(vupdate, "CACHE", link):
                with self.assertRaises(SystemExit):
                    vupdate.command_status(None)

if __name__=="__main__": unittest.main()
