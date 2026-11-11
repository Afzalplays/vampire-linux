# Vampire Settings defaults

The initial settings profile is stored in settings/defaults.json. It defines product defaults for appearance, top panel, floating dock, voice access and update policy. It is a schema seed for the future settings service, not yet wired into a running desktop shell.

Transparency is configurable from 0 to 60 percent. The UI should label presets Off, Low, Medium, High and Extreme. Security prompts and credential dialogs must remain opaque and readable regardless of desktop transparency.

Voice access is off by default, uses push-to-talk by default, does not retain raw audio and never enables arbitrary shell command execution. Updates notify the user and ask before rebooting by default.
