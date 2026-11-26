# Vampire Display diagnostics

`vdisplay` is a read-only DRM/KMS connector inventory for the early Desktop
edition.

## Usage

```sh
vdisplay
vdisplay --help
```

The command reads connector status and advertised modes from
`/sys/class/drm`. For isolated tests, set `VAMPIRE_DRM_SYSFS` to a fixture
directory. It rejects a symlinked sysfs root, skips symlinked connector entries,
and validates mode strings before printing them.

## Important limitations

The modes listed by sysfs are advertised modes, not necessarily the mode
currently active on the display. This command does not change resolution,
rotation, scaling, refresh rate, or compositor configuration. It is a
diagnostic foundation for later adaptive display controls; do not describe it
as automatic display scaling.

Physical validation is still required for laptop panels, external monitors,
hot-plug, multi-monitor layouts, HiDPI scaling, touchscreens and rotation.
