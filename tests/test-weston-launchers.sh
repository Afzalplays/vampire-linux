#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
APP_LAUNCHER="$ROOT/rootfs-overlay/usr/bin/vampire-app"
test -x "$APP_LAUNCHER" || { echo "Missing tracked Vampire app launcher: $APP_LAUNCHER" >&2; ls -la "$ROOT/rootfs-overlay/usr/bin" >&2; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/foot" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$FOOT_ARGS"
MOCK
cat > "$TMP/bin/app" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$APP_ARGS"
MOCK
cat > "$TMP/bin/terminal" <<'MOCK'
#!/bin/sh
echo terminal > "$TERMINAL_ARGS"
MOCK
chmod +x "$TMP/bin/"*

for app in launcher files settings software monitor; do
  FOOT_ARGS="$TMP/$app.args" PATH="$TMP/bin:$PATH" "$APP_LAUNCHER" "$app"
  case "$app" in
    launcher) grep -Fxq /usr/bin/vlauncher "$TMP/$app.args" ;;
    files) grep -Fxq /usr/bin/vfiles "$TMP/$app.args" ;;
    settings) grep -Fxq /usr/bin/vdesktop "$TMP/$app.args"; grep -Fxq -- --settings "$TMP/$app.args" ;;
    software) grep -Fxq /usr/bin/vsoftware "$TMP/$app.args" ;;
    monitor) grep -Fxq /usr/bin/vmonitor "$TMP/$app.args" ;;
  esac
done
if PATH="$TMP/bin:$PATH" "$APP_LAUNCHER" unknown >/dev/null 2>&1; then
  echo "Vampire app launcher accepted an unknown app" >&2; exit 1
fi
grep -q 'path=/usr/bin/vampire-terminal' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app launcher' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app files' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app settings' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app software' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app monitor' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"

LAUNCHER="$ROOT/rootfs-overlay/usr/bin/vlauncher"
VAMPIRE_ROOT="$ROOT/rootfs-overlay" sh "$LAUNCHER" --check > "$TMP/desktop-check.out"
grep -Fq "all seven desktop commands and six application icons are present" "$TMP/desktop-check.out"
if VAMPIRE_ROOT="$TMP/empty-root" sh "$LAUNCHER" --check > "$TMP/desktop-check-fail.out" 2>&1; then
  echo "Vampire Launcher accepted an incomplete desktop payload" >&2; exit 1
fi
grep -Fq "desktop payload validation failed" "$TMP/desktop-check-fail.out"
sh "$LAUNCHER" --list > "$TMP/catalog"
sh "$LAUNCHER" --json > "$TMP/catalog.json"
python3 - "$TMP/catalog.json" "$ROOT" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[2])
items = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert [item["id"] for item in items] == ["terminal", "files", "settings", "software", "monitor"]
assert all(set(item) == {"id", "name", "description", "category", "icon"} for item in items)
assert all(item["category"] in {"system", "utilities"} for item in items)
icons = [item["icon"] for item in items]
assert len(icons) == len(set(icons)), "each launcher app must have its own icon"
for item in items:
    icon = root / "rootfs-overlay" / item["icon"].lstrip("/")
    assert icon.is_file(), icon
    assert item["icon"].endswith("/" + item["id"] + ".png"), item
PY
grep -Fxq 'terminal|Terminal|Open Vampire Terminal' "$TMP/catalog"
grep -Fxq 'files|Files|Browse and manage files' "$TMP/catalog"
grep -q 'settings|Settings|Configure appearance' "$TMP/catalog"
sh "$LAUNCHER" --search Settings | grep -Fq 'settings|Settings|Configure appearance'
if sh "$LAUNCHER" --search no-such-app >/dev/null 2>&1; then
  echo "Vampire Launcher search returned a missing app" >&2; exit 1
fi
APP_ARGS="$TMP/app.args" VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" --launch files
grep -Fxq files "$TMP/app.args"
TERMINAL_ARGS="$TMP/terminal.args" VAMPIRE_TERMINAL_CMD="$TMP/bin/terminal" sh "$LAUNCHER" --launch terminal
grep -q terminal "$TMP/terminal.args"
if VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" --launch nonexistent >/dev/null 2>&1; then
  echo "Vampire Launcher dispatched an unknown app" >&2; exit 1
fi
printf 'file\nfiles\n0\n' | APP_ARGS="$TMP/menu.args" VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" > "$TMP/menu.out"
grep -q 'Search applications or enter an app ID' "$TMP/menu.out"
grep -Eq "^  files +Files +Browse and manage files$" "$TMP/menu.out"
grep -Fxq files "$TMP/menu.args"

# Interactive launcher accepts stable IDs and case-insensitive display names.
printf 'Files\n0\n' | APP_ARGS="$TMP/name.args" VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" > "$TMP/name.out"
grep -Fxq files "$TMP/name.args"
grep -q 'app ID/name' "$TMP/name.out"
printf 'TERMINAL\n0\n' | TERMINAL_ARGS="$TMP/name-terminal.args" VAMPIRE_TERMINAL_CMD="$TMP/bin/terminal" sh "$LAUNCHER" > /dev/null
grep -Fxq terminal "$TMP/name-terminal.args"


# Partial searches launch a unique match directly and offer numbered choices
# when multiple applications match the query.
printf 'file\n0\n' | APP_ARGS="$TMP/partial.args" VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" > "$TMP/partial.out"
grep -Fxq files "$TMP/partial.args"
printf 's\n3\n0\n' | APP_ARGS="$TMP/multiple.args" VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" > "$TMP/multiple.out"
grep -q '1) Files' "$TMP/multiple.out"
grep -q '2) Settings' "$TMP/multiple.out"
grep -q '3) Software Center' "$TMP/multiple.out"
grep -Fxq software "$TMP/multiple.args"
printf 's\n9\n0\n' | APP_ARGS="$TMP/invalid-selection.args" VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" > "$TMP/invalid-selection.out"
grep -q 'outside the result list' "$TMP/invalid-selection.out"

# Each clickable Weston panel launcher has a bundled Vampire icon.
python3 - "$ROOT" <<'PY'
import pathlib, re, struct, sys, zlib
root = pathlib.Path(sys.argv[1])
config = (root / "rootfs-overlay/etc/xdg/weston/weston.ini").read_text()
blocks = re.findall(r"(?ms)^\[launcher\]\s*\n(.*?)(?=^\[|\Z)", config)
assert len(blocks) == 6, len(blocks)
expected = {
    "/usr/bin/vampire-terminal": "terminal.png",
    "/usr/bin/vampire-app launcher": "launcher.png",
    "/usr/bin/vampire-app files": "files.png",
    "/usr/bin/vampire-app settings": "settings.png",
    "/usr/bin/vampire-app software": "software.png",
    "/usr/bin/vampire-app monitor": "monitor.png",
}
for block in blocks:
    values = dict(line.split("=", 1) for line in block.splitlines() if "=" in line)
    assert values.get("path") in expected, values
    icon = values.get("icon", "")
    assert icon == "/usr/share/vampire/icons/" + expected[values["path"]], (values, icon)
    path = root / "rootfs-overlay" / icon.lstrip("/")
    data = path.read_bytes()
    assert data[:8] == bytes((137,80,78,71,13,10,26,10)), path
    offset, seen_ihdr, idat = 8, False, []
    while offset < len(data):
        length = struct.unpack(">I", data[offset:offset+4])[0]
        kind = data[offset+4:offset+8]
        payload = data[offset+8:offset+8+length]
        crc = struct.unpack(">I", data[offset+8+length:offset+12+length])[0]
        assert zlib.crc32(kind + payload) & 0xffffffff == crc, path
        if kind == b"IHDR":
            width, height, depth, color, comp, filt, interlace = struct.unpack(">IIBBBBB", payload)
            assert (width,height,depth,color,comp,filt,interlace) == (64,64,8,6,0,0,0)
            seen_ihdr = True
        elif kind == b"IDAT": idat.append(payload)
        offset += length + 12
    assert seen_ihdr and len(zlib.decompress(b"".join(idat))) == 64 * (1 + 64 * 4), path
PY

echo "Vampire Weston desktop launcher tests passed."
