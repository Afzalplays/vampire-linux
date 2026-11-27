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

    def test_service_worker_refreshes_navigation_and_limits_offline_fallback(self):
        worker = (MOBILE / "sw.js").read_text()
        self.assertIn('const CACHE="vampire-mobile-v3"', worker)
        self.assertIn('if(request.mode==="navigate")', worker)
        self.assertIn('fetch(request)', worker)
        self.assertIn('.catch(()=>caches.match("./index.html"))', worker)
        self.assertIn('key.startsWith("vampire-mobile-")', worker)
        self.assertIn('caches.match(request).then(cached=>cached||fetch(request)', worker)

    def test_install_ui_reports_platform_specific_fallback_and_user_choice(self):
        app = (MOBILE / "app.js").read_text()
        for marker in (
            "navigator.standalone",
            "display-mode",
            "isAppleMobileDevice",
            "open this page in Safari",
            "Install app or Add to Home Screen",
            'choice.outcome === "accepted"',
            "Installation was cancelled",
            "appinstalled",
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, app)

    def test_service_worker_failure_is_reported_without_breaking_online_portal(self):
        app = (MOBILE / "app.js").read_text()
        self.assertIn('navigator.serviceWorker.register("./sw.js")', app)
        self.assertIn("Offline support could not be enabled", app)
        self.assertIn("portal still works online", app)

    def test_phone_image_warning_is_visible(self):
        html = (MOBILE / "index.html").read_text()
        self.assertIn("not installable phone images", html)


if __name__ == "__main__":
    unittest.main()
