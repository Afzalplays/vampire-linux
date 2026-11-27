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
        self.assertIn('const CACHE="vampire-mobile-v5"', worker)
        self.assertIn('if(request.mode==="navigate")', worker)
        self.assertIn("fetch(request)", worker)
        self.assertIn("async function offlinePage(request)", worker)
        self.assertIn('path.endsWith("/experience.html")', worker)
        self.assertIn("async function networkFirst(request)", worker)
        self.assertIn("if(response.ok)return cacheResponse(request,response)", worker)
        self.assertIn("return await offlinePage(request)||response", worker)
        self.assertIn("return await offlinePage(request)||response", worker)
        self.assertIn("return offlinePage(request)", worker)
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
        for marker in ("Revealable center dock", "All apps", "Quick panel", "Notifications", "Wallpaper & display", "Allines", "brightness", "volume", "prefers-reduced-motion", "wallpaper-file", "battery-live", "storage-live", "ram-live", "updateDeviceStats", "navigator.getBattery", "navigator.storage?.estimate", "theme-drift", "Animated themes", "Aurora flow", "Deep ocean", "motion-level", "reduce-motion"):
            with self.subTest(marker=marker):
                self.assertIn(marker, prototype)
        self.assertNotIn(";\\\\nconst PREF_KEY", prototype)
        self.assertNotIn(";\\\\n\\\\nlet batteryManager", prototype)
        self.assertNotIn("\\\\nlet batteryManager", prototype)
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
        self.assertIn("Wallpaper files up to 2 MB are saved locally", prototype)

    def test_launcher_page_has_its_own_install_metadata(self):
        prototype = (MOBILE / "experience.html").read_text()
        for marker in ('rel="manifest"', 'apple-mobile-web-app-capable', 'apple-touch-icon', '<title>Vampire OS Launcher</title>', 'navigator.serviceWorker.register("./sw.js")'):
            with self.subTest(marker=marker):
                self.assertIn(marker, prototype)

    def test_launcher_app_shortcuts_route_to_preview_panels(self):
        prototype = (MOBILE / "experience.html").read_text()
        for marker in ('Phone:"caller"', '"Vampire Caller":"caller"', '"Game Booster":"game"', 'Terminal:"terminal"', 'Allines:"assistant"'):
            with self.subTest(marker=marker):
                self.assertIn(marker, prototype)

    def test_desktop_launcher_uses_revealable_center_dock_without_taskbar(self):
        prototype = (MOBILE / "experience.html").read_text()
        for marker in ('@media(min-width:800px)', 'Revealable center dock', '.edge-dock{left:50%;top:auto;bottom:24px', '.edge-dock:hover,.edge-dock:focus-within{opacity:1}', '.bottom-nav{display:none}', 'aria-label="Launcher dock"'):
            with self.subTest(marker=marker):
                self.assertIn(marker, prototype)

    def test_launcher_app_drawer_supports_categories_and_sorting(self):
        prototype = (MOBILE / "experience.html").read_text()
        for marker in ('id="app-category"', 'id="app-sort"', 'value="communication"', 'value="productivity"', 'value="games"', 'value="az"', 'value="za"', 'function renderAppDrawer()', 'el.dataset.category', 'appCategory.addEventListener("change",renderAppDrawer)', 'appSort.addEventListener("change",renderAppDrawer)'):
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

    def test_quick_panel_brightness_and_volume_preferences_persist(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn('brightness:document.querySelector("#brightness").value', prototype)
        self.assertIn('volume:document.querySelector("#volume").value', prototype)
        self.assertIn('["brightness",75,10,100],["volume",60,0,100]', prototype)
        self.assertIn('style.filter="brightness("', prototype)
        self.assertIn('id==="brightness")document.querySelector("#home").style.filter', prototype)
        self.assertIn('savePreferences()}));', prototype)

    def test_wallpaper_is_saved_locally_and_restored_on_next_launch(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn("2*1024*1024", prototype)
        self.assertIn("new FileReader()", prototype)
        self.assertIn("savedPreferences.wallpaper=reader.result", prototype)
        self.assertIn("wallpaper:savedPreferences.wallpaper||null", prototype)
        self.assertIn('typeof savedPreferences.wallpaper==="string"', prototype)
        self.assertIn("data:image\\/(png|jpeg|webp|gif);base64,", prototype)
        self.assertIn("Wallpaper files up to 2 MB are saved locally", prototype)

    def test_launcher_panels_support_keyboard_escape_and_touch_dismissal(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn('e.key==="Escape"', prototype)
        self.assertIn('panel.addEventListener("touchstart"', prototype)
        self.assertIn('panel.addEventListener("touchend"', prototype)

    def test_launcher_dialogs_hide_from_accessibility_tree_and_trap_keyboard_focus(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn('panel.setAttribute("aria-hidden","true")', prototype)
        self.assertIn('e.key!=="Tab"', prototype)
        self.assertIn('e.shiftKey&&(document.activeElement===first||!active.contains(document.activeElement))', prototype)
        self.assertIn('!e.shiftKey&&(document.activeElement===last||!active.contains(document.activeElement))', prototype)

    def test_mobile_first_roadmap_prioritizes_android_boot_port(self):
        roadmap = (ROOT / "docs" / "MOBILE-SUPPORT.md").read_text()
        self.assertIn("Mobile-first priority approved", roadmap)
        self.assertIn("Build the native ARM64 mobile base", roadmap)
        self.assertIn("Produce a device-specific boot/recovery image", roadmap)
        self.assertIn("Desktop/server release polish after the mobile boot milestone", roadmap)
        self.assertNotIn("before starting phone-OS porting", roadmap)

    def test_mobile_support_never_claims_an_ordinary_iphone_boot_image(self):
        roadmap = (ROOT / "docs" / "MOBILE-SUPPORT.md").read_text()
        self.assertIn("ordinary iPhones are not a supported target for replacing iOS", roadmap)
        self.assertIn("PWA/native companion", roadmap)
        self.assertIn("device-specific", roadmap)

    def test_launcher_has_exit_action_in_dock_and_mobile_shortcuts(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertGreaterEqual(prototype.count("data-exit-launcher"), 3)
        self.assertIn('aria-label="Exit launcher"', prototype)
        self.assertIn("Native launcher exit will return Home", prototype)
        self.assertIn("Launcher preview cannot close the phone OS", prototype)

    def test_launcher_supports_local_animated_wallpaper_selection(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn('accept="image/png,image/jpeg,image/webp,image/gif"', prototype)
        self.assertIn('["image/png","image/jpeg","image/webp","image/gif"]', prototype)
        self.assertIn("Animated wallpaper applied:", prototype)
        self.assertIn('id="clear-wallpaper"', prototype)
        self.assertIn("2*1024*1024", prototype)

    def test_security_features_are_deferred_to_bootable_mobile_release(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn("Reserved for the bootable Vampire Mobile OS release", prototype)
        self.assertIn("Native permissions arrive with the bootable OS", prototype)

    def test_launcher_clock_recorder_and_media_previews_clean_up_resources(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn('setInterval(()=>{clock.textContent=new Date().toLocaleTimeString()', prototype)
        self.assertIn('new MediaRecorder(stream)', prototype)
        self.assertIn('navigator.mediaDevices.getUserMedia({audio:true})', prototype)
        self.assertIn('URL.revokeObjectURL(objectUrl)', prototype)
        self.assertIn('activePreviewCleanup();activePreviewCleanup=()=>{}', prototype)

    def test_contacts_calendar_and_security_shortcut_have_safe_launcher_behaviour(self):
        prototype = (MOBILE / "experience.html").read_text()
        self.assertIn('vampire-launcher-contacts', prototype)
        self.assertIn('shown.setMonth(shown.getMonth()+1)', prototype)
        self.assertIn('shown.setMonth(shown.getMonth()-1)', prototype)
        self.assertIn('Security features are intentionally deferred', prototype)
        self.assertNotIn('Contacts:"contacts"', prototype)
        self.assertNotIn('Security:"terminal"', prototype)
