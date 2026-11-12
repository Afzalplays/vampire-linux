#!/usr/bin/env python3
"""Apply validated Vampire appearance preferences to the live Wayland session."""
from __future__ import annotations

import os
import pathlib
import re
import tempfile

ALLOWED = {
    "theme": {"dark", "light", "system"},
    "accent": {"crimson", "rose", "ice", "violet"},
    "surface_transparency": {"0", "10", "20", "30", "40", "50", "60"},
    "terminal_opacity": {str(n) for n in range(0, 101, 10)},
    "top_panel": {"true", "false"},
    "reduced_motion": {"true", "false"},
}

def fail(message: str) -> None:
    raise SystemExit("vsettings apply: " + message)

def load_settings() -> dict[str, str]:
    path = pathlib.Path(os.environ.get("VAMPIRE_SETTINGS_FILE", "/etc/vampire/settings.conf"))
    if not path.is_file():
        fail("settings file is missing; run vsettings reset first")
    values: dict[str, str] = {}
    try:
        for raw in path.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                fail("malformed settings line")
            key, value = line.split("=", 1)
            if key not in ALLOWED:
                # Other preferences are validated by the shell frontend but do
                # not have a corresponding Weston/Foot setting yet.
                continue
            if key in values:
                fail("duplicate setting: " + key)
            if value not in ALLOWED[key]:
                fail("invalid value for " + key)
            values[key] = value
    except OSError as exc:
        fail("cannot read settings: " + str(exc))
    return values

def replace_key(text: str, key: str, value: str) -> str:
    pattern = re.compile(r"(?m)^" + re.escape(key) + r"=.*$")
    updated, count = pattern.subn(key + "=" + value, text)
    if count != 1:
        fail("base configuration must contain exactly one " + key + " entry")
    return updated

def atomic_write(path: pathlib.Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix="." + path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(content)
        os.chmod(temp_name, 0o600)
        os.replace(temp_name, path)
    except Exception:
        try:
            os.unlink(temp_name)
        except OSError:
            pass
        raise

def main() -> None:
    values = load_settings()
    theme = values.get("theme", "dark")
    accent = values.get("accent", "crimson")
    transparency = int(values.get("surface_transparency", "20"))
    opacity = int(values.get("terminal_opacity", "90"))
    top_panel = values.get("top_panel", "true") == "true"
    reduced_motion = values.get("reduced_motion", "false") == "true"

    if theme == "light":
        background, foot_background, foot_foreground = "0xfff2f2f6", "f2f2f6", "17171d"
    else:
        background, foot_background, foot_foreground = "0xff08080c", "08080c", "e8e8ef"
    accent_rgb = {
        "crimson": "6f2030",
        "rose": "71324c",
        "ice": "24546b",
        "violet": "483267",
    }[accent]
    alpha = max(0, min(255, 255 - transparency * 255 // 100))
    panel_color = "0x" + format(alpha, "02x") + accent_rgb
    motion = "none" if reduced_motion else "fade"
    panel_position = "top" if top_panel else "none"

    base_weston = pathlib.Path(os.environ.get("VAMPIRE_WESTON_BASE", "/etc/xdg/weston/weston.ini"))
    base_foot = pathlib.Path(os.environ.get("VAMPIRE_FOOT_BASE", "/etc/xdg/foot/foot.ini"))
    output_weston = pathlib.Path(os.environ.get("VAMPIRE_WESTON_RUNTIME_CONFIG", "/run/vampire/weston.ini"))
    config_home = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", "/run/vampire"))
    if not base_weston.is_file() or not base_foot.is_file():
        fail("Weston or Foot base configuration is missing")
    try:
        weston_text = base_weston.read_text(encoding="utf-8")
        foot_text = base_foot.read_text(encoding="utf-8")
    except OSError as exc:
        fail("cannot read base configuration: " + str(exc))

    for key, value in (
        ("background-color", background),
        ("panel-color", panel_color),
        ("panel-position", panel_position),
        ("animation", motion),
        ("close-animation", motion),
        ("startup-animation", motion),
    ):
        weston_text = replace_key(weston_text, key, value)
    for key, value in (
        ("background", foot_background),
        ("foreground", foot_foreground),
        ("alpha", format(opacity / 100, ".2f")),
    ):
        foot_text = replace_key(foot_text, key, value)

    atomic_write(output_weston, weston_text)
    atomic_write(config_home / "foot" / "foot.ini", foot_text)
    print("Vampire Desktop appearance applied for the next graphical session.")

if __name__ == "__main__":
    main()
