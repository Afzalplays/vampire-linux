# Vampire Display diagnostics

The Weston desktop uses a bundled 640×360 Vampire dark wallpaper at `/usr/share/vampire/wallpaper.png`, rendered with `background-type=scale-crop` to fill displays with differing aspect ratios. The wallpaper is a restrained near-black and crimson abstract gradient without character or creature branding.

`vdisplay` is a read-only DRM/KMS connector inventory for the early Desktop
edition.

## Usage

```sh
vdisplay
vdisplay --help
vdisplay --json
```

The command reads connector status and advertised modes from
`/sys/class/drm`. For isolated tests, set `VAMPIRE_DRM_SYSFS` to a fixture
directory. It rejects a symlinked sysfs root, skips symlinked connector entries,
and validates mode strings before printing them. The `--json` option emits a
machine-readable object containing connector names, connection states,
advertised modes, and aggregate counts; it is suitable for future desktop
settings and diagnostics clients. Installed Desktop rootfs validation also
runs `vdisplay --json` in a chroot and parses the empty-inventory response. It
also resets, validates and applies the installed Desktop settings defaults,
then checks the generated Weston and Foot runtime configuration. These checks
exercise packaged executables and runtime dependencies before the installed
disk is booted.

## Adaptive wallpaper fitting

Weston uses `background-type=scale-crop` for the bundled wallpaper. The compositor scales the image to cover the active output while preserving its aspect ratio, so the desktop background follows the display's current resolution without a fixed pixel-mode setting. Displays with a different aspect ratio may crop the outer edges; the logo and main title remain centered in the composition. This is wallpaper fitting only: it does not change the monitor's resolution, refresh rate, orientation, or per-output HiDPI scale.

## Important limitations

The modes listed by sysfs are advertised modes, not necessarily the mode
currently active on the display. This command does not change resolution,
rotation, scaling, refresh rate, or compositor configuration. It is a
diagnostic foundation for later adaptive display controls; do not describe it
as automatic display scaling.

Physical validation is still required for laptop panels, external monitors,
hot-plug, multi-monitor layouts, HiDPI scaling, touchscreens and rotation.

## Vampire Launcher

The Weston desktop-shell panel now includes six clickable application launchers (Terminal, Launcher, Files, Settings, Software Center and System Monitor), each using its own bundled Vampire PNG icon. These are native Weston panel launchers, not a separate floating dock. The keyboard-driven launcher is also available as `vlauncher` from a terminal and from the panel launcher entry. Use `vlauncher --list` to inspect
the stable application IDs, `vlauncher --search TEXT` to filter the catalog,
and `vlauncher --launch APP-ID` to dispatch a known application. In its
interactive prompt, enter either an application ID or its displayed name;
exact ID/name matching is case-insensitive. A partial query prints matching
catalog entries so the user can choose an exact ID or name.

This is a keyboard-driven application catalog hosted in the terminal. It is
not yet a native graphical launcher, floating dock, or replacement for the
Weston desktop shell.
The launcher also exposes `vlauncher --json`, a stable machine-readable
catalog containing each app's `id`, `name`, `description`, and `category`.
This is intended as an integration boundary for a future graphical launcher;
it does not itself provide graphical UI.

## Console menu integration

The Vampire Desktop console preview exposes Display connector inventory as menu item 26. It launches `vdisplay` for a read-only report of connected/disconnected DRM connectors and advertised modes; use `vdisplay --json` from a terminal when a machine-readable inventory is needed. This diagnostic does not alter output modes or scaling.
