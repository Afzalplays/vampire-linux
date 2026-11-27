# Vampire Settings defaults

The product-level profile is described in `settings/defaults.json`. The
runtime key/value defaults in `rootfs-overlay/etc/vampire/settings.defaults`
are copied to `/etc/vampire/settings.conf` on first live boot. The
`vsettings` command validates values and atomically replaces the settings
file; `vdesktop` exposes these preferences through its console preview menu.

The Weston input profile enables libinput tap-to-click for supported touchpads. Keyboard repeat rate (20–60 keys per second) and initial delay (200–800 ms) are configurable through Settings and applied at the next graphical-session start; defaults are 40 keys per second and 400 ms. Physical keyboard and touchpad validation remains pending.

The current settings backend stores theme, accent, surface transparency,
blur preset, terminal opacity, dock size/position/auto-hide/magnification,
top-panel visibility, panel indicators, reduced motion, update channel and
voice-access preference. Theme, accent, panel visibility, panel transparency, reduced motion and
terminal opacity and the native panel clock visibility are applied on the next graphical-session start. The panel clock uses a 24-hour format by default and can be hidden. Panel transparency controls the Weston panel background; it does not make all windows transparent. Blur, dock size/position/auto-hide/magnification, date, network and power indicators remain stored-only until the custom Vampire compositor and native settings UI are implemented.

Surface transparency is configurable from 0 to 60 percent. Security prompts
and credential dialogs must remain opaque and readable regardless of desktop
transparency.

Voice access is off by default, uses push-to-talk by default, does not retain
raw audio and never enables arbitrary shell command execution. Updates notify
the user and ask before rebooting by default.
