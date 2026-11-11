# Vampire Settings defaults

The initial settings profile is stored in settings/defaults.json. It defines product defaults for appearance, top panel, floating dock, voice access and update policy. It seeds `/etc/vampire/settings.conf` on first live boot. The current `vsettings` CLI validates and stores these preferences, and the `vdesktop` console launcher exposes a small appearance menu. No graphical compositor currently consumes the appearance settings, so opacity and blur are saved preferences rather than active visual effects.

Transparency is configurable from 0 to 60 percent. The UI should label presets Off, Low, Medium, High and Extreme. Security prompts and credential dialogs must remain opaque and readable regardless of desktop transparency.

Voice access is off by default, uses push-to-talk by default, does not retain raw audio and never enables arbitrary shell command execution. Updates notify the user and ask before rebooting by default.
