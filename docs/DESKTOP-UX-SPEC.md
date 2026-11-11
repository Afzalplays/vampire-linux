# Vampire Desktop — layout and interaction specification

**Status:** Approved design direction from the desktop preview discussion; implementation is not yet complete.

## 1. Overall layout

Vampire Desktop uses a familiar desktop workflow with its own visual identity. It is not a full-screen launcher and it must not copy Windows wholesale.

### Top system panel (macOS-inspired)

The top panel is persistent and replaces the traditional bottom taskbar/system tray.

- **Left:** Vampire Button (metallic V glyph with white-to-crimson gradient), active app name and optional workspace indicator.
- **Right:** date, clock, Wi-Fi/network status, audio, battery/power state, notifications and quick settings.
- Clock opens calendar and time settings.
- Network icon opens connection controls and connection diagnostics.
- Quick settings exposes Wi-Fi, Bluetooth, audio, display brightness, power mode and VPN state where supported.
- Panel must remain readable over light and dark wallpaper regions using a subtle translucent/opaque backing.
- Panel height and icon spacing are configurable; keyboard and screen-reader access are required.

### Floating application dock (hover-to-reveal)

There is **no permanent bottom taskbar**.

- A floating dock is horizontally centred near the bottom screen edge.
- It contains pinned apps, running-app indicators, and a launcher shortcut.
- It hides automatically after pointer movement away and reappears when the pointer reaches the configured bottom-edge activation zone.
- A short reveal animation is allowed; respect reduced-motion settings.
- Dock size, magnification, spacing and screen-edge position are configurable.
- Running applications remain discoverable through keyboard shortcuts and the window switcher even while the dock is hidden.
- Do not reserve a large permanent strip of screen space for the dock.

### Desktop workspace

- Default wallpaper is the supplied Vampire OS black/crimson V-logo wallpaper, subject to asset licensing confirmation.
- Desktop icons are optional and can be disabled.
- Windows are movable, resizable and snap/tiling capable.
- Custom Vampire window buttons replace generic branding; close/minimize/maximize remain familiar and accessible.
- Use restrained translucent graphite surfaces with red highlights. Avoid making every surface glow.
- Low-effects mode disables blur, shadows and animation for weaker GPUs and low-memory systems.

## 2. Vampire Button

- Distinct angular V symbol with a white-to-crimson gradient.
- Opens the Vampire Launcher.
- Launcher has search, pinned/frequent apps, categories, recent files and power actions.
- Keyboard shortcut (configurable) opens it.
- Accessible name: "Vampire Launcher"; tooltip and focus ring are mandatory.

## 3. System panel behaviour

- Date/time use the user's locale and timezone.
- Network state distinguishes disconnected, connected, captive portal and VPN.
- Battery controls appear only when a battery is detected.
- Notification centre shows actionable notifications with per-app controls.
- Quick settings must not require opening a full settings application for common toggles.
- Never expose passwords, Wi-Fi secrets or private keys in panel UI or logs.

## 4. Terminal and vfetch

Vampire Terminal is translucent by default on capable compositors, with a user-adjustable opacity. Blur is optional, not required. Provide a solid-background fallback and readable contrast mode.

The vfetch output should use the following composition:

- Custom V ASCII logo on the left, with `V A M P I R E` and `O S` below.
- `user@vampire-os` header and separator on the right.
- System information aligned in a clean right column.
- Fields in this order: OS, Host, Kernel, Uptime, Packages, Shell, Display, DE, WM, Theme, Terminal, CPU, GPU, Memory, Local IP, Locale.
- Coloured status dots at the bottom.
- Missing hardware or display information must show `Not detected` or `Unknown`, never crash.

## 5. Desktop applications and shortcuts

The default dock should be small and useful: Vampire Files, Vampire Terminal, Vampire Software Center, Vampire Settings and Vampire Monitor. Additional apps are pinned by the user.

Keyboard shortcuts should include launcher, terminal, file manager, app switcher, workspace switcher, lock screen and screenshot. All shortcuts must be configurable and documented.

## 6. Performance and accessibility

- Target a responsive desktop on low-memory x86_64 hardware; define and publish measured minimums only after testing.
- Avoid background animation loops when the desktop is idle.
- Support reduced motion, high contrast, font scaling, keyboard-only navigation and screen readers.
- Make blur, transparency and dock magnification optional.
- Do not trade text legibility or secure prompts for visual effects.

## 7. Acceptance checklist

- [ ] No permanent bottom taskbar.
- [ ] Top panel shows date/time and available connectivity/system controls.
- [ ] Floating centred dock hides and reveals on hover/edge activation.
- [ ] Dock does not reserve permanent screen space.
- [ ] Vampire Button opens the app launcher.
- [ ] Windows have branded, accessible controls.
- [ ] Terminal transparency is adjustable with solid fallback.
- [ ] vfetch matches the approved left-logo/right-information composition.
- [ ] Low-effects and reduced-motion modes work.
- [ ] Keyboard navigation and multi-monitor layouts are tested.
