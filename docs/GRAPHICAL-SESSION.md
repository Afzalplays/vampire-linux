# Vampire graphical session — live desktop preview

The x86_64 Desktop configuration includes upstream Weston, its DRM backend
and desktop shell, eudev device discovery, the Foot Wayland terminal and
DejaVu fonts. The Weston preview uses a Vampire-dark palette and automatically
opens Foot with the branded Vampire Shell as its interactive shell.

Run \`vgraphical\` from a local console on a machine with a supported DRM/KMS
graphics device. This launches the configured Weston session. The preview
provides a real Wayland terminal and can run the available Vampire OS commands;
it is still **not the finished Vampire Desktop**. The approved Vampire top
panel, floating dock, branded launcher, custom window controls, graphical
file manager and graphical settings application remain unimplemented.

A usable \`/dev/dri/card0\`, kernel DRM driver and suitable firmware are required.
Virtual machines without virtual GPU/DRM support will not show a graphical
session. This early live preview is root/seat based, not a multi-user display
manager. Audio, touchpads, multi-monitor support and GPU compatibility are not
certified. Boot remains console-first; if Weston cannot acquire DRM/VT, return
to the text console.

A release desktop still needs a dedicated Vampire shell, non-root session
management, display manager, audio/network settings, accessibility, window
management integration and hardware validation.
