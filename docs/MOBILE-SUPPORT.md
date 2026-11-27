# Vampire OS mobile support

**Status:** Mobile-first priority approved. The immediate deliverable is the Vampire Mobile launcher experience; the next major engineering track is a real, bootable Android/Linux mobile edition. Desktop and server polish is deferred while this mobile track is active. Desktop/server release polish after the mobile boot milestone. The current PWA is still a prototype and is not a bootable phone OS.

## Goals

Vampire OS should be usable from a phone for project downloads, documentation, release notes and remote administration. Its web interfaces must adapt to narrow touch screens, portrait/landscape orientation, safe-area insets and larger accessibility text.

## Vampire Mobile interface prototype (new)

`mobile/experience.html` is an interactive, touch-first visual prototype for the proposed phone experience. It includes a left-edge taskbar, searchable app drawer, notification panel, quick-setting tiles, brightness/volume sliders, local wallpaper preview, accent colour, appearance toggle and the Allines assistant concept. The wallpaper is selected locally in the browser and is not uploaded. Quick toggles and launcher entries are simulated UI state only; they do not control phone radios, installed apps or protected system settings. The assistant uses browser speech synthesis where available and does not connect to a cloud AI service.

This prototype is a design and interaction preview, not a phone operating system. Native app compatibility, real system panels, telephony, biometric security, encryption, verified boot and hardware-level settings require a device-specific native implementation.

## Three distinct deliverables

### 1. Mobile web experience (Android and iOS)

The static, installable Progressive Web App (PWA) project portal lives in `mobile/`. It provides project/release/documentation links, a responsive layout, install guidance and a static offline shell.

- Responsive layouts at phone, tablet and desktop widths.
- Touch targets, keyboard accessibility, scalable text and high-contrast mode.
- Respect `prefers-reduced-motion`, dark/light appearance and safe-area insets.
- PWA manifest, app icon, offline cache for the explicit static asset allowlist, and installation/update feedback.
- Refresh navigations from the network when online, retain the last cached portal page for offline navigation, and keep static assets cache-first; old Vampire mobile cache versions are retired on activation.
- Detect standalone installation, expose the browser install prompt when available, and provide Safari Home Screen instructions for iPhone/iPad.
- HTTPS required for service-worker installation.
- Do not cache credentials, private keys, tokens or privileged API responses.
- A PWA is a web app; it does **not** boot or replace the phone's operating system.

On iPhone, users can add the PWA to the Home Screen through Safari where supported. On Android, supported browsers can install it. Browser and OS capabilities differ. ordinary iPhones are not a supported target for replacing iOS; iPhone support remains a PWA/native companion.

### 2. Native Android launcher milestone

`mobile/android/` now contains a native Android HOME-app shell around the bundled touch UI. Android can offer it as a default launcher after the user explicitly selects it. It uses immersive system-bar mode and the in-app power button returns to Android Home through a native intent. A dedicated CI workflow builds a debug APK. This is an Android application running on top of Android, **not** a bootable Vampire OS image; system services and hardware integration remain incomplete.

### 3. ARM64 QEMU bring-up target

`build/vampire_mobile_qemu_defconfig` and `build/build-mobile-qemu.sh` define a separate AArch64 Buildroot profile for QEMU `virt`. This is a generic kernel/initramfs bring-up path only; it is not a phone image and does not validate touch, cellular, cameras, sensors, suspend or vendor firmware. A device-specific port remains blocked on selecting a real reference device.

### 4. Native Android/Linux mobile edition

A true mobile OS image is a separate ARM64 port, not an x86_64 ISO resized for a phone. Before promising device downloads, select specific supported devices and validate:

- SoC, bootloader unlock policy, boot chain and partition layout.
- Linux kernel, device tree, vendor firmware and hardware drivers.
- Display/touch, GPU acceleration, audio, Wi-Fi, Bluetooth, cellular modem, GPS, cameras, sensors and suspend/resume.
- Verified boot, encryption, recovery/rollback and update delivery.
- A touch-first shell, on-screen keyboard, adaptive settings and phone/tablet layouts.

Initial scope should be a small, explicitly listed Android-device compatibility target. Generic Android APK support or a generic ARM64 ISO does not prove a bootable phone port.

### 5. iOS

A custom Vampire OS kernel/ISO cannot be installed as a replacement for iOS on ordinary iPhones. iOS is controlled by Apple's signed boot chain and platform restrictions. The supported near-term iPhone experience is the PWA or a separately developed native iOS companion app distributed under Apple's rules. Do not advertise an iOS bootable ISO.

## Download catalogue and compatibility

The download page must identify the target before offering an artifact:

| Artifact | Target | Phone installation |
| --- | --- | --- |
| Vampire Desktop ISO | x86_64 PC | Not a phone image |
| Vampire Server ISO | x86_64 PC/server | Not a phone image |
| Mobile PWA | Android/iOS browser | Install/add to Home Screen |
| Android device image | Only named, tested ARM64 devices | Device-specific flashing instructions |
| Native iOS companion | iPhone/iPad | App Store/TestFlight distribution, if built |

Every release artifact should show architecture, edition, version, checksum, signature status and tested device/firmware matrix. Never offer an image as compatible until it has passed device-specific boot and hardware tests.

## Delivery phases

1. [x] Build the responsive PWA portal and installable offline shell (`mobile/`).
2. [x] Create the Vampire Mobile launcher prototype with app drawer, quick panel, notifications, Allines preview, Caller/Game Booster/Terminal previews, browser-available stats and built-in themes.
3. [ ] Complete launcher beta quality: responsive layouts, app icon consistency, touch gestures, accessibility, local settings persistence and offline/update behaviour.
4. [x] Add native Android HOME launcher shell and automated debug-APK build (launcher only; not a replacement OS).\n5. [x] Add generic ARM64 QEMU kernel/initramfs bring-up profile (emulator only).\n6. [ ] Select and document a supported Android reference device (SoC, bootloader, partition map, firmware and unlock policy) before building a device image.
7. [ ] Build the native ARM64 mobile base: kernel, device tree, vendor firmware, init, graphics/display, touch, audio, Wi-Fi/Bluetooth and power management.
8. [ ] Build the native touch shell and core mobile services: lock screen, notifications, quick settings, app lifecycle, permissions, keyboard, telephony/data where supported, camera and sensors.
9. [ ] Produce a device-specific boot/recovery image; validate boot, install, encryption, update/rollback, suspend/resume and recovery on the reference device.
10. [ ] Keep iPhone support as a PWA/native companion; do not promise replacing or booting over iOS on ordinary iPhones.
11. [ ] Resume desktop/server release polish after the mobile boot milestone.

## Acceptance criteria

- Portal is usable at 320px, 360px, 390px, 768px and desktop widths without horizontal overflow.
- Portrait and landscape layouts work; safe-area insets are respected.
- Touch targets, scalable text, keyboard navigation and reduced-motion preferences are supported.
- PWA install guidance and offline static-page behaviour are contract-tested; real browser/device installation still requires Android and iOS device validation.
- Download labels prevent users from mistaking x86_64 ISOs for phone images.
- Native mobile claims are backed by named-device boot, driver, power-management and recovery tests.


## Expanded Vampire Mobile concept

The mobile interface prototype now includes Allines voice-command recognition where the browser supports the Web Speech API, a simulated screen-lock flow, Vampire Caller UI, Game Booster profiles, an expanded quick panel, and a simulated Vampire Security Lab terminal command. The app drawer reports live search-result counts and empty states, panels move keyboard focus into the active dialog and restore it when closed, and wallpaper previews accept PNG, JPEG, WebP and GIF files up to 2 MB, save them locally in browser storage and support animated GIF / animated WebP playback where the browser supports it. These are UI demonstrations only. The browser cannot lock or unlock the device, authenticate biometrically, identify or block live callers, tune CPU/GPU performance, or run native security utilities. Voice recognition must never be treated as an authentication factor. A real unlock must remain behind the device's trusted PIN/biometric lock screen. Caller identification needs lawful data provenance, explicit permissions, opt-out and correction workflows. Security tools must be signed, permission-scoped and used only on systems the operator is authorized to test.


## Live device dashboard and built-in themes

The mobile experience prototype includes a best-effort live dashboard. Battery percentage, charging state and estimated charge/discharge time are shown only when the browser exposes the Battery Status API. Storage figures are the PWA origin's browser storage usage/quota, not the phone's total free disk space. Device RAM is shown only as the coarse `navigator.deviceMemory` estimate where supported; JavaScript heap usage, when exposed, is labelled as web-app memory rather than total system RAM. Unsupported readings are explicitly marked unavailable. iOS Safari commonly restricts these hardware APIs, so full battery, disk and RAM telemetry requires a native companion or OS service.

Built-in CSS animated themes (Aurora, Nebula and Ocean), a static battery-friendly theme, animation intensity and a reduce-motion setting are included directly in the mobile experience; no separate theme app or download is required. The interface also respects the platform's `prefers-reduced-motion` preference. These are PWA-level visual themes, not system-wide iOS themes.


## Current beta scope decision

The immediate release target is the **Vampire Mobile Launcher app**, not the bootable mobile OS. The launcher should present a usable home screen, app drawer, quick panel, notifications, settings, wallpapers, themes and clearly labelled app previews. The Exit Launcher action is present in the taskbar/dock; in this browser/PWA prototype it can navigate back where possible or explain the platform Home gesture. A web page cannot hide Android/iOS system navigation or force itself to replace the system home screen. The later native Android launcher will use Android's supported HOME/default-launcher and exit-to-home integration. Device security, real permissions, telephony and privileged controls are intentionally deferred until the bootable Vampire Mobile OS release and its native security client are available. Do not present simulated security controls as real protection.
