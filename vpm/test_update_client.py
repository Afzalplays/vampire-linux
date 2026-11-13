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
if __name__=="__main__": unittest.main()
