import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
MOBILE = ROOT / "mobile"


class MobilePortalContractTests(unittest.TestCase):
    def test_required_pwa_files_exist(self):
        for name in ("index.html", "styles.css", "app.js", "manifest.webmanifest", "sw.js", "icon.svg"):
            with self.subTest(name=name):
                self.assertTrue((MOBILE / name).is_file())

    def test_manifest_has_installable_metadata(self):
        manifest = json.loads((MOBILE / "manifest.webmanifest").read_text())
        self.assertEqual(manifest["name"], "Vampire OS")
        self.assertEqual(manifest["display"], "standalone")
        self.assertEqual(manifest["orientation"], "any")
        self.assertTrue(manifest["icons"])

    def test_page_declares_mobile_and_apple_home_screen_support(self):
        html = (MOBILE / "index.html").read_text()
        for marker in ('name="viewport"', 'rel="manifest"', 'apple-mobile-web-app-capable', 'apple-touch-icon'):
            with self.subTest(marker=marker):
                self.assertIn(marker, html)

    def test_layout_has_small_screen_safe_area_and_reduced_motion_rules(self):
        css = (MOBILE / "styles.css").read_text()
        for marker in ("@media(max-width:700px)", "env(safe-area-inset-top", "env(safe-area-inset-bottom", "prefers-reduced-motion", "min-width:320px"):
            with self.subTest(marker=marker):
                self.assertIn(marker, css)

    def test_service_worker_caches_only_static_same_origin_get_assets(self):
        worker = (MOBILE / "sw.js").read_text()
        self.assertIn('request.method!=="GET"', worker)
        self.assertIn("url.origin!==self.location.origin", worker)
        self.assertIn("!ASSETS.has(url.pathname)", worker)
        self.assertIn("url.search", worker)
        self.assertNotRegex(worker, re.compile(r"Authorization|localStorage|sessionStorage|indexedDB", re.I))

    def test_phone_image_warning_is_visible(self):
        html = (MOBILE / "index.html").read_text()
        self.assertIn("not installable phone images", html)


if __name__ == "__main__":
    unittest.main()
