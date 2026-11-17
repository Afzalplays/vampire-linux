# Vampire graphical session — live desktop preview

The x86_64 Desktop configuration includes upstream Weston, its DRM backend
and desktop shell, eudev device discovery, the Foot Wayland terminal and
DejaVu fonts. The Weston preview uses a Vampire-dark palette, a top panel and
clickable launchers for Terminal, Files, Settings and Software Center.
Weston automatically opens Foot with the branded Vampire Shell as its
interactive shell.

Run \`vgraphical\` from a local console on a machine with a supported DRM/KMS
graphics device. This launches the configured Weston session. The preview
provides a real Wayland terminal and working console applications through
panel launchers; it is still **not the finished Vampire Desktop**. The
approved custom Vampire top panel, floating dock, branded window controls,
native graphical file manager and graphical settings application remain
unimplemented.

A usable \`/dev/dri/card0\`, kernel DRM driver and suitable firmware are required.
Virtual machines without virtual GPU/DRM support will not show a graphical
session. This early live preview is root/seat based, not a multi-user display
manager. Audio, touchpads, multi-monitor support and GPU compatibility are not
certified. Boot remains console-first; if Weston cannot acquire DRM/VT, return
to the text console.

A release desktop still needs a dedicated Vampire shell, non-root session
management, display manager, audio/network settings, accessibility, window
management integration and hardware validation.

## Persistent desktop preferences

Desktop preferences live in `/etc/vampire/settings.conf`; validated defaults
are shipped in `/etc/vampire/settings.defaults`. During boot,
`/usr/lib/vampire/settings-bootstrap` creates the initial file atomically,
leaves valid user preferences untouched, and backs up an invalid file under
`/var/lib/vampire` before attempting recovery. Invalid defaults are rejected,
and a failed recovery does not overwrite the existing settings file. The appearance applier also rejects symlinked preference inputs, base configurations and output directories before writing runtime configuration.

Use `vsettings list`, `vsettings set KEY VALUE`, `vsettings validate` and
`vsettings reset` to manage preferences. Settings that have a corresponding
Weston or Foot configuration mapping are applied to the next graphical
session; dock, blur and several panel-item preferences are stored but are not
yet implemented by this early desktop preview.
