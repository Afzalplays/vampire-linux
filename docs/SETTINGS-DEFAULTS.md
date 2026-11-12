# Vampire Settings defaults

The product-level profile is described in `settings/defaults.json`. The
runtime key/value defaults in `rootfs-overlay/etc/vampire/settings.defaults`
are copied to `/etc/vampire/settings.conf` on first live boot. The
`vsettings` command validates values and atomically replaces the settings
file; `vdesktop` exposes these preferences through its console preview menu.

The current settings backend stores theme, accent, surface transparency,
blur preset, terminal opacity, dock size/position/auto-hide/magnification,
top-panel visibility, panel indicators, reduced motion, update channel and
voice-access preference. Theme, accent, panel visibility, panel transparency, reduced motion and
terminal opacity are applied on the next graphical-session start. Panel
transparency controls the Weston panel background; it does not make all
windows transparent. Blur, dock size/position/auto-hide/magnification and
panel indicator preferences remain stored-only until the custom Vampire
compositor and native settings UI are implemented.

Surface transparency is configurable from 0 to 60 percent. Security prompts
and credential dialogs must remain opaque and readable regardless of desktop
transparency.

Voice access is off by default, uses push-to-talk by default, does not retain
raw audio and never enables arbitrary shell command execution. Updates notify
the user and ask before rebooting by default.
