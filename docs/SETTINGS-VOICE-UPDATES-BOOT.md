# Vampire OS — Settings, Voice Access, Updates and Boot Specification

**Status:** Product specification; these features are planned unless explicitly marked implemented elsewhere.

## Vampire Settings

A first-party settings application with a custom Vampire layout, not a copy of Windows Settings or macOS System Settings.

### Navigation
- Overview: device identity, edition, system health and update status.
- Personalization: wallpaper, accent, theme, transparency, blur, dock and panel.
- Display: resolution, refresh rate, scaling, multi-monitor and night light.
- Sound: output/input devices, volume, microphone permissions and alerts.
- Network: Ethernet, Wi-Fi, VPN, proxy, DNS and connection diagnostics.
- Bluetooth: adapters, pairing and trusted devices.
- Apps: installed apps, default apps, permissions and startup apps.
- Accounts: users, groups, sign-in and authentication methods.
- Privacy & Security: firewall, app permissions, disk encryption state, Secure Boot state, audit log and security recommendations.
- Updates: OS, security, firmware and application updates.
- System: hardware, storage, power, services, logs, recovery and about.
- Accessibility: voice access, screen reader, magnifier, contrast, captions, keyboard and reduced motion.

### Personalization — glass/transparency control
Provide a slider with five named presets and a numeric custom value:
- Off / Opaque: 0% transparency.
- Low: 15%.
- Medium: 30%.
- High: 45%.
- Extreme: 60% maximum surface transparency.

These are surface-alpha targets, not a promise that every window can composite at those values. Text and critical controls must retain contrast. Blur is a separate Off/Low/Medium/High control. Include a live preview and safe reset. Low-effects mode disables expensive blur and animation. Password prompts, privilege dialogs and security warnings must remain opaque.

Other controls: wallpaper and lock screen, dark/light/automatic theme, accent, icons, cursor, font and UI scale, top-panel visibility, floating dock size/magnification/position/auto-hide, window button placement, terminal opacity/blur/font, animation level, reduced motion and import/export theme profiles.

## System updates

Distinguish:
1. Security updates with advisory severity.
2. Core OS updates (kernel, init, libraries and services).
3. Desktop and first-party app updates.
4. Third-party application updates.
5. Firmware updates only when hardware and firmware tooling support them.

Required workflow:
- Fetch repository metadata over HTTPS and verify Minisign signatures.
- Show origin, version change, download size, changelog and security advisory.
- Resolve dependencies/conflicts before downloading.
- Download to staging and verify hashes/signatures.
- Apply as an atomic transaction using an immutable deployment or snapshot-capable design.
- Keep a previous known-good deployment and provide rollback.
- Recover safely from power loss and interrupted upgrades.
- Support scheduled checks, notifications, security-only and all-update policies.
- Never reboot without consent except a configured managed-server policy.
- Never bypass signature checks with -y.

Important: vpm update currently refreshes package indexes only. It is not a full OS updater. Do not enable system upgrades until file ownership, transactions and rollback are implemented.

## Voice Access

A first-party voice service and settings page. Prefer offline recognition where models are available; online recognition is opt-in and must disclose data handling.

Command intents:
- Open an installed application.
- Open a file or folder using its default application.
- Search user-accessible files.
- Create a file or folder in the current approved location.
- Rename or move a file after confirming exact source and destination.
- Delete by moving to Trash by default; permanent deletion requires separate confirmation.
- Dictate into the focused field only after explicit dictation activation.
- Lock, sign out, restart and shut down only after confirmation.
- Run command is disabled by default. If enabled, show the exact command and require confirmation; never execute arbitrary recognised speech as shell input.

Language coverage: the product goal is broad multilingual support using pluggable engines and downloadable models. Do not claim literally every language is supported until tested. Publish a matrix of language, dialect, engine, model, offline availability and accuracy testing.

Safety and privacy:
- Push-to-talk is the default; wake word is opt-in.
- Show microphone-active indicator and immediate mute.
- Local processing by default where supported; no raw audio retention by default.
- Confirm destructive, privileged, external-network and account actions.
- Respect Unix permissions and sandbox boundaries.
- Ask when filenames are ambiguous.
- Background audio cannot authorise privileged actions.
- Provide keyboard and screen-reader alternatives.

## BIOS/UEFI boot and recovery

Support x86_64 boot from USB and virtual media on tested systems. BIOS includes legacy BIOS and modern UEFI firmware.

- UEFI is primary; design for signed boot chain and documented Secure Boot key enrollment.
- Legacy BIOS is a compatibility target where bootloader/hardware support it.
- Boot menu: Desktop Live, Server Live/Rescue, Install, tested memory diagnostic and Recovery.
- Installer detects firmware mode, architecture, RAM, storage and network.
- Guided and advanced manual partitioning with clear destructive-operation confirmation.
- Create an EFI System Partition for UEFI and suitable BIOS boot layout for legacy systems.
- Install bootloader to selected target disk, never the build host.
- Include boot repair and recovery environment.
- Test OVMF/UEFI and SeaBIOS/QEMU plus real hardware before release.
- Publish a hardware compatibility matrix; do not claim universal BIOS support.

## Release gates
No feature is production-ready until automated tests, threat review, accessibility review and supported VM/hardware testing pass.
