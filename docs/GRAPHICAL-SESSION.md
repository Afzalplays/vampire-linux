# Vampire graphical session — bring-up stage

The x86_64 Buildroot configuration includes upstream Weston, its DRM backend
and desktop shell, plus eudev device discovery.

Run `vgraphical` from a local console on a machine with a supported DRM/KMS
graphics device. This launches the upstream Weston desktop shell. It is a
graphics-stack bring-up milestone, **not the finished Vampire Desktop**. The
approved Vampire top panel, floating dock, branded launcher, custom window
controls, file manager and settings GUI remain unimplemented.

A usable `/dev/dri/card0`, kernel DRM driver and suitable firmware are required.
Virtual machines without virtual GPU/DRM support will not show a graphical
session. This early live preview is root/seat based, not a multi-user display
manager. Audio, touchpads, multi-monitor support and GPU compatibility are
not certified. Boot remains console-first; if Weston cannot acquire DRM/VT,
return to the text console.

A release desktop still needs a dedicated Vampire shell, non-root session
management, display manager, audio/network settings, accessibility, window
management integration and hardware validation.
