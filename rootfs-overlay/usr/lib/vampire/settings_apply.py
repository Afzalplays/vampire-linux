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
    "surface_transparency": {str(n) for n in range(0, 61, 10)},
    "blur": {"off", "low", "medium", "high", "extreme"},
    "terminal_opacity": {str(n) for n in range(0, 101, 10)},
    "dock_size": {"small", "medium", "large"},
    "dock_position": {"bottom-center", "left-center", "right-center"},
    "dock_auto_hide": {"true", "false"},
    "dock_magnification": {"true", "false"},
    "top_panel": {"true", "false"},
    "show_date": {"true", "false"},
    "show_clock": {"true", "false"},
    "show_network": {"true", "false"},
    "show_power": {"true", "false"},
    "reduced_motion": {"true", "false"},
    "update_channel": {"stable", "testing"},
    "voice_access": {"true", "false"},
    "keyboard_repeat_rate": {"20", "30", "40", "50", "60"},
    "keyboard_repeat_delay": {"200", "300", "400", "500", "600", "700", "800"},
}

def fail(message: str) -> None:
    raise SystemExit("vsettings apply: " + message)

def load_settings() -> dict[str, str]:
    path = pathlib.Path(os.environ.get("VAMPIRE_SETTINGS_FILE", "/etc/vampire/settings.conf"))
    reject_symlink_path(path)
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
            if key in values:
                fail("duplicate setting: " + key)
            if key not in ALLOWED:
                fail("unknown setting: " + key)
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

def reject_symlink_path(path: pathlib.Path) -> None:
    absolute = path.absolute()
    for component in reversed((absolute, *absolute.parents)):
        if component.is_symlink():
            fail("refusing symlinked configuration path: " + str(component))

def atomic_write(path: pathlib.Path, content: str) -> None:
    reject_symlink_path(path.parent)
    reject_symlink_path(path)
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

def adaptive_output_config(drm_root: pathlib.Path) -> str:
    """Return Weston scale hints, following only trusted sysfs device links."""
    if drm_root.is_symlink() or not drm_root.is_dir():
        return ""
    devices_root = pathlib.Path(os.environ.get("VAMPIRE_SYSFS_DEVICES_ROOT", "/sys/devices"))
    try:
        devices_root = devices_root.resolve(strict=True)
    except OSError:
        return ""
    sections: list[str] = []
    for connector in sorted(drm_root.glob("card[0-9]*-*")):
        name = connector.name
        if not re.fullmatch(r"card[0-9]+-[A-Za-z0-9_-]+", name):
            continue
        connector_dir = connector
        if connector.is_symlink():
            try:
                connector_dir = connector.resolve(strict=True)
                connector_dir.relative_to(devices_root)
            except (OSError, ValueError):
                continue
        if not connector_dir.is_dir():
            continue
        status_file = connector_dir / "status"
        modes_file = connector_dir / "modes"
        if status_file.is_symlink() or not status_file.is_file():
            continue
        try:
            if status_file.read_text(encoding="ascii").strip() != "connected":
                continue
            modes: list[tuple[int, int]] = []
            if not modes_file.is_symlink() and modes_file.is_file():
                for raw in modes_file.read_text(encoding="ascii").splitlines():
                    match = re.fullmatch(r"([0-9]{2,5})x([0-9]{2,5})", raw.strip())
                    if match:
                        modes.append((int(match.group(1)), int(match.group(2))))
        except OSError:
            continue
        scale = 2 if any(width >= 2800 and height >= 1600 for width, height in modes) else 1
        output_name = name.split("-", 1)[1]
        sections.append(f"\n[output]\nname={output_name}\nscale={scale}\n")
    return "".join(sections)


def main() -> None:
    values = load_settings()
    theme = values.get("theme", "dark")
    accent = values.get("accent", "crimson")
    transparency = int(values.get("surface_transparency", "20"))
    opacity = int(values.get("terminal_opacity", "90"))
    top_panel = values.get("top_panel", "true") == "true"
    reduced_motion = values.get("reduced_motion", "false") == "true"
    repeat_rate = values.get("keyboard_repeat_rate", "40")
    repeat_delay = values.get("keyboard_repeat_delay", "400")

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
    clock_format = "minutes-24h" if values.get("show_clock", "true") == "true" else "none"

    base_weston = pathlib.Path(os.environ.get("VAMPIRE_WESTON_BASE", "/etc/xdg/weston/weston.ini"))
    base_foot = pathlib.Path(os.environ.get("VAMPIRE_FOOT_BASE", "/etc/xdg/foot/foot.ini"))
    output_weston = pathlib.Path(os.environ.get("VAMPIRE_WESTON_RUNTIME_CONFIG", "/run/vampire/weston.ini"))
    config_home = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", "/run/vampire"))
    reject_symlink_path(base_weston)
    reject_symlink_path(base_foot)
    reject_symlink_path(output_weston.parent)
    reject_symlink_path(config_home)
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
        ("clock-format", clock_format),
        ("animation", motion),
        ("close-animation", motion),
        ("startup-animation", motion),
    ):
        weston_text = replace_key(weston_text, key, value)
    weston_text = replace_key(weston_text, "repeat-rate", repeat_rate)
    weston_text = replace_key(weston_text, "repeat-delay", repeat_delay)
    weston_text += adaptive_output_config(pathlib.Path(os.environ.get("VAMPIRE_DRM_SYSFS", "/sys/class/drm")))

    for key, value in (
        ("background", foot_background),
        ("foreground", foot_foreground),
        ("alpha", format(opacity / 100, ".2f")),
    ):
        foot_text = replace_key(foot_text, key, value)

    atomic_write(output_weston, weston_text)
    atomic_write(config_home / "foot" / "foot.ini", foot_text)
    print("Vampire Desktop appearance applied for the next graphical session.")
    applied = {
        "theme", "accent", "surface_transparency", "terminal_opacity",
        "top_panel", "show_clock", "reduced_motion",
        "keyboard_repeat_rate", "keyboard_repeat_delay",
    }
    pending = sorted(set(values) - applied)
    if pending:
        print("Stored but not applied by this desktop build: " + ", ".join(pending))

if __name__ == "__main__":
    main()
