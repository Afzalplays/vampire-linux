# Vampire OS mobile support

**Status:** Responsive PWA portal implemented. Native Android device images and a native iOS companion remain planned and are not release deliverables.

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

On iPhone, users can add the PWA to the Home Screen through Safari where supported. On Android, supported browsers can install it. Browser and OS capabilities differ.

### 2. Native Android/Linux mobile edition

A true mobile OS image is a separate ARM64 port, not an x86_64 ISO resized for a phone. Before promising device downloads, select specific supported devices and validate:

- SoC, bootloader unlock policy, boot chain and partition layout.
- Linux kernel, device tree, vendor firmware and hardware drivers.
- Display/touch, GPU acceleration, audio, Wi-Fi, Bluetooth, cellular modem, GPS, cameras, sensors and suspend/resume.
- Verified boot, encryption, recovery/rollback and update delivery.
- A touch-first shell, on-screen keyboard, adaptive settings and phone/tablet layouts.

Initial scope should be a small, explicitly listed Android-device compatibility target. Generic Android APK support or a generic ARM64 ISO does not prove a bootable phone port.

### 3. iOS

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

1. [x] Responsive project/download portal and PWA shell with install-state feedback and offline static asset caching (`mobile/`).
2. Secure mobile-friendly server administration UX, with authentication and MFA.
3. Select an Android ARM64 reference device and build a hardware-support matrix.
4. Prototype and test a device-specific mobile image and touch-first shell.
5. Evaluate a native iOS companion app only if the PWA is insufficient.

## Acceptance criteria

- Portal is usable at 320px, 360px, 390px, 768px and desktop widths without horizontal overflow.
- Portrait and landscape layouts work; safe-area insets are respected.
- Touch targets, scalable text, keyboard navigation and reduced-motion preferences are supported.
- PWA install guidance and offline static-page behaviour are contract-tested; real browser/device installation still requires Android and iOS device validation.
- Download labels prevent users from mistaking x86_64 ISOs for phone images.
- Native mobile claims are backed by named-device boot, driver, power-management and recovery tests.
