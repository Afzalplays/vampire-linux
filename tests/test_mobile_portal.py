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
        self.assertEqual(manifest["start_url"], "./experience.html")
        self.assertEqual(manifest["id"], "./experience.html")
        self.assertTrue(manifest["icons"])

    def test_manifest_exposes_launcher_and_portal_shortcuts(self):
        manifest = json.loads((MOBILE / "manifest.webmanifest").read_text())
        shortcuts = {item["short_name"]: item for item in manifest["shortcuts"]}
        self.assertEqual(shortcuts["Launcher"]["url"], "./experience.html")
        self.assertEqual(shortcuts["Portal"]["url"], "./index.html")
        self.assertTrue(all(item["icons"] for item in manifest["shortcuts"]))

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
        self.assertIn('const CACHE="vampire-mobile-v4"', worker)
        self.assertIn('if(request.mode==="navigate")', worker)
        self.assertIn("fetch(request)", worker)
        self.assertIn('.catch(()=>caches.match(request).then(cached=>cached||caches.match("./index.html")))', worker)
        self.assertIn('key.startsWith("vampire-mobile-")', worker)
        self.assertIn("caches.match(request).then(cached=>cached||fetch(request)", worker)

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

    def test_vampire_mobile_prototype_has_requested_interactive_surfaces(self):
        prototype = (MOBILE / "experience.html").read_text()
        for marker in ("Left-side taskbar", "All apps", "Quick panel", "Notifications", "Wallpaper & display", "Allines", "brightness", "volume", "prefers-reduced-motion", "wallpaper-file", "battery-live", "storage-live", "ram-live", "updateDeviceStats", "navigator.getBattery", "navigator.storage?.estimate", "theme-drift", "Animated themes", "Aurora flow", "Deep ocean", "motion-level", "reduce-motion"):
            with self.subTest(marker=marker):
                self.assertIn(marker, prototype)
        self.assertIn("URL.createObjectURL", prototype)
        self.assertNotIn(";\\\\nconst PREF_KEY", prototype)
        self.assertNotIn(";\\\\n\\\\nlet batteryManager", prototype)
        self.assertEqual(prototype.count('querySelector("#voice-assistant").addEventListener'), 1)
        self.assertIn("../rootfs-overlay/usr/share/vampire/wallpaper.png", prototype)
        self.assertIn("aria-pressed", prototype)
        for marker in ("Vampire Caller", "Game Booster", "Vampire Terminal", "lockscreen", "SpeechRecognition", "vampire -activate hacker mode -y", "vsecurity scan --safe", "secure-unlock"):
            with self.subTest(marker=marker):
                self.assertIn(marker, prototype)

    def test_launcher_preferences_persist_locally_and_fail_safely(self):
        prototype = (MOBILE / "experience.html").read_text()
        for marker in ("vampire-mobile-preferences-v1", "readPreferences()", "savePreferences()", "localStorage.getItem", "localStorage.setItem", "savedPreferences.quick", "savedPreferences.reduceMotion"):
            with self.subTest(marker=marker):
                self.assertIn(marker, prototype)
        self.assertIn("Browser storage is unavailable", prototype)
        self.assertIn("Wallpaper images are previewed locally", prototype)

    def test_launcher_page_has_its_own_install_metadata(self):
        prototype = (MOBILE / "experience.html").read_text()
        for marker in ('rel="manifest"', 'apple-mobile-web-app-capable', 'apple-touch-icon', '<title>Vampire OS Launcher</title>'):
            with self.subTest(marker=marker):
                self.assertIn(marker, prototype)

    def test_launcher_app_shortcuts_route_to_preview_panels(self):
        prototype = (MOBILE / "experience.html").read_text()
        for marker in ('Phone:"caller"', '"Vampire Caller":"caller"', '"Game Booster":"game"', 'Terminal:"terminal"', 'Allines:"assistant"', 'Security:"terminal"'):
            with self.subTest(marker=marker):
                self.assertIn(marker, prototype)

    def test_launcher_search_reports_empty_and_matching_results(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn('id="app-search-status"', prototype)
        self.assertIn('aria-live="polite"', prototype)
        self.assertIn("No apps match your search", prototype)
        self.assertIn("toLocaleLowerCase()", prototype)

    def test_launcher_panels_manage_focus_and_accessibility_state(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn("lastPanelTrigger", prototype)
        self.assertIn('x.setAttribute("aria-hidden",String(!active))', prototype)
        self.assertIn("lastPanelTrigger.focus()", prototype)

    def test_wallpaper_preview_limits_size_and_releases_object_urls(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn("12*1024*1024", prototype)
        self.assertIn("URL.revokeObjectURL", prototype)
        self.assertIn('window.addEventListener("pagehide"', prototype)

    def test_launcher_panels_support_keyboard_escape_and_touch_dismissal(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn('e.key==="Escape"', prototype)
        self.assertIn('panel.addEventListener("touchstart"', prototype)
        self.assertIn('panel.addEventListener("touchend"', prototype)
