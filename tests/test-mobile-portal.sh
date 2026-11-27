#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
python3 - "$ROOT/mobile" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
html = (root / "index.html").read_text()
js = (root / "app.js").read_text()
css = (root / "styles.css").read_text()
sw = (root / "sw.js").read_text()
manifest = json.loads((root / "manifest.webmanifest").read_text())
assert manifest["display"] == "standalone"
assert manifest["orientation"] == "any"
assert manifest["scope"] == "./"
assert 'name="viewport"' in html and "viewport-fit=cover" in html
assert 'id="install-button"' in html
assert 'id="install-status"' in html
assert 'id="connection-status"' in html
assert 'role="status" aria-live="polite"' in html
assert 'addEventListener("online", updateConnectionStatus)' in js
assert 'addEventListener("offline", updateConnectionStatus)' in js
assert "navigator.onLine" in js
assert "previously cached portal pages and assets" in js
assert "focus-visible" in css and "forced-colors:active" in css
assert "pointer:coarse" in css
for asset in ("index.html", "styles.css", "app.js", "manifest.webmanifest", "icon.svg"):
    assert (root / asset).is_file(), asset
    assert f'"./{asset}"' in sw, f"{asset} missing from service-worker cache allowlist"
assert "request.method!==\"GET\"" in sw
assert "url.origin!==self.location.origin" in sw
assert "url.search" in sw
print("Vampire mobile PWA install, offline, responsive and accessibility checks passed.")
PY
