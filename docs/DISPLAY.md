# Vampire Display diagnostics

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

## Important limitations

The modes listed by sysfs are advertised modes, not necessarily the mode
currently active on the display. This command does not change resolution,
rotation, scaling, refresh rate, or compositor configuration. It is a
diagnostic foundation for later adaptive display controls; do not describe it
as automatic display scaling.

Physical validation is still required for laptop panels, external monitors,
hot-plug, multi-monitor layouts, HiDPI scaling, touchscreens and rotation.

## Vampire Launcher

The keyboard-driven launcher is available as `vlauncher` from a terminal and
from the Weston desktop-shell launcher entry. Use `vlauncher --list` to inspect
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
