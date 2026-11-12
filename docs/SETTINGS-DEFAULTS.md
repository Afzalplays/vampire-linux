# Vampire Settings defaults

The product-level profile is described in `settings/defaults.json`. The
runtime key/value defaults in `rootfs-overlay/etc/vampire/settings.defaults`
are copied to `/etc/vampire/settings.conf` on first live boot. The
`vsettings` command validates values and atomically replaces the settings
file; `vdesktop` exposes these preferences through its console preview menu.

The current settings backend stores theme, accent, surface transparency,
blur preset, terminal opacity, dock size/position/auto-hide/magnification,
top-panel visibility, panel indicators, reduced motion, update channel and
voice-access preference. Transparency and blur are saved preferences only:
the current Weston preview does not consume them. The final Vampire compositor
must apply these settings to its own surfaces and dock.

Surface transparency is configurable from 0 to 60 percent. Security prompts
and credential dialogs must remain opaque and readable regardless of desktop
transparency.

Voice access is off by default, uses push-to-talk by default, does not retain
raw audio and never enables arbitrary shell command execution. Updates notify
the user and ask before rebooting by default.
