# Vampire OS — Product & Engineering Blueprint
**Project:** Vampire OS x86_64  
**Editions:** Vampire Desktop / Vampire Server  
**Brand:** VampireNodes  
**Design motto:** Power • Privacy • Freedom  
**Status:** Proposed product blueprint — implementation is incremental and experimental.

---

## 1. Product vision

Vampire OS is an independently assembled, lightweight Linux distribution for desktop users, developers, security professionals, and server operators. It is not a Debian, Ubuntu, Arch, or Kali derivative. The target system is assembled from upstream source projects with its own build system, package format, repository, init/service design, installer, desktop shell, and administration tools.

The product has two coordinated editions:

- **Vampire Desktop:** a polished, efficient daily-use desktop with a Windows-11-familiar workflow, distinct Vampire identity, transparent terminal, file manager, settings, app store, and optional remote desktop.
- **Vampire Server:** a minimal headless-first server operating system with a web/terminal administration interface, secure remote access, service management, monitoring, and multi-host fleet management.

Both editions share the same package ecosystem, security foundations, update model, hardware abstraction, and branding.

## 2. Design language and brand system

### 2.1 Visual reference

Use the supplied Vampire OS wallpaper as the primary art-direction reference:

- Deep black / charcoal background.
- Crimson-red light trails and restrained red glow.
- Metallic, angular V emblem with red and white/silver highlights.
- Red smoke or atmospheric texture used sparingly.
- High-contrast white typography and small red accent details.
- Premium, technical, cinematic appearance; avoid clutter and excessive gothic decoration.

The wallpaper is a visual reference, not a requirement to make every UI panel smoky or glowing. Keep controls readable and lightweight.

### 2.2 Design tokens

- Primary background: near-black.
- Surface: charcoal / graphite with optional translucent glass.
- Accent: crimson red.
- Logo highlight: gradient from white/silver to crimson red.
- Text: off-white primary, muted grey secondary.
- Status colours: semantic green, amber, red; do not use brand red for every status.
- Motion: short, subtle transitions; provide reduced-motion setting.
- Typography: modern sans-serif for UI; monospaced for terminal and technical data.

### 2.3 Vampire Button

Replace the conventional branded application/menu button with the custom **Vampire Button**:

- Custom angular V glyph.
- White-to-red gradient fill/highlight.
- Accessible focus ring and hover/pressed states.
- Opens the Vampire Launcher / application menu.
- Never rely on colour alone; retain tooltip and accessible label.

Use the same logo language for boot branding, login screen, installer, desktop shell, and system tools.

---

## 3. Vampire Desktop Edition

### 3.1 Desktop experience

The desktop should feel familiar to Windows 11 users without copying its complete interface. It should remain recognizably Linux and Vampire-branded. The approved layout uses a macOS-inspired top system panel and a floating hover-to-reveal dock instead of a permanent bottom taskbar.

Core layout:

- Clean desktop workspace with wallpaper support.
- macOS-inspired top system panel with Vampire Button on the left and date, time, network and system controls on the right.
- Floating, horizontally centred bottom dock that hides when not in use and reveals on hover/edge activation; no permanent bottom taskbar.
- Window title bars and controls with Vampire styling.
- Rounded but restrained window corners, consistent spacing, keyboard navigation.
- Virtual workspaces and window tiling/snap layouts.
- Searchable application launcher.
- Notifications, quick settings and audio/network/battery controls.
- Lock screen, login manager, user switching and session logout.
- Multi-monitor, HiDPI scaling and fractional scaling where supported.

Do not make the entire desktop one giant full-screen launcher. Normal resizable windows and a practical workspace are required.

### 3.2 Window controls

Create Vampire-branded window controls rather than copying Windows controls:

- Custom close, maximize/restore and minimize glyphs.
- Consistent hover/focus/pressed feedback.
- Configurable button placement and accessibility size.
- Keyboard shortcuts for window management.
- Compositor-controlled window decorations; applications should remain usable with standard Linux window protocols.

### 3.3 Core desktop applications

First-party applications to build or integrate:

1. **Vampire Files** — file manager with tabs, split view, search, archive handling, network locations, removable drives, permissions view and safe trash.
2. **Vampire Terminal** — transparent/translucent background, adjustable opacity, blur only when compositor supports it, profiles, tabs, split panes, searchable scrollback, copy/paste safeguards and accessible contrast.
3. **Vampire Settings** — display, themes, wallpaper, keyboard, mouse, sound, network, users, privacy, updates and power.
4. **Vampire Software Center** — searchable GUI catalogue using the same signed repositories as VPM.
5. **Vampire Monitor** — CPU, memory, storage, network, process and temperature monitoring.
6. **Vampire Archive** — archive viewer/extractor with safe path handling.
7. **Vampire Connect** — remote desktop and remote host connection front end.
8. **Vampire Help** — offline documentation and troubleshooting.

Keep the default install lean. Optional applications should be installed from the Software Center.

### 3.4 Wallpaper and personalization

- Ship the supplied Vampire OS wallpaper as the default brand wallpaper, subject to confirming its licensing/ownership.
- Allow user wallpapers, solid colours and light/dark accent variants.
- Provide a low-resource wallpaper mode without smoke animation or heavy effects.
- Keep transparency configurable, including a fully opaque accessibility/performance mode.

---

## 4. Vampire Software Center and VPM

### 4.1 One package ecosystem

VPM is the system package manager. Vampire Software Center is its graphical front end. They must share the same package catalogue, trust policy, installed-package database and transaction engine.

Desired command experience:

```sh
vpm update
vpm search firefox
vpm info firefox
vpm install firefox
vpm install vfetch -y
vpm install git curl wget htop -y
vpm upgrade
vpm remove firefox
vpm list
vpm history
vpm rollback
```

The `-y` flag means explicitly accept the reviewed transaction without interactive confirmation. It must not bypass signature checks, privilege checks, warnings about destructive actions, or security policy. For operations with data-loss risk, require explicit confirmation even with `-y`.

### 4.2 Required package-manager capabilities

- Signed stable, testing and community repositories.
- Search, package details, categories, screenshots and publisher/maintainer identity.
- Dependency resolution and version constraints.
- Architecture and edition compatibility checks.
- Download progress, cancellation and resumable downloads.
- Package hashes and signed repository metadata.
- File ownership database, conflict detection and safe removal.
- Atomic transactions, rollback and interrupted-upgrade recovery.
- Update history, changelogs, security advisories and pinned versions.
- Offline package install/export for disconnected servers.
- User-scoped apps separated from system packages.
- Source provenance, license, build recipe and SBOM for official packages.
- Repository priority and package origin clearly shown.

### 4.3 Package sources

Official packages should be built from upstream source using reproducible recipes wherever practical. Do not import another distribution's package database as the OS foundation. Third-party binary compatibility packages must be clearly labelled and isolated where possible.

The repository must never silently install unsigned packages or execute arbitrary package scripts as root.

### 4.4 Software Center categories

- Internet and communication.
- Office and productivity.
- Graphics, design and media.
- Development, compilers, SDKs and IDEs.
- Games and compatibility tools.
- System utilities and hardware tools.
- Networking and remote administration.
- Security and privacy.
- Server, databases, web stacks and observability.
- Drivers and firmware.

The catalogue should offer many useful applications, but availability depends on upstream source, license, architecture, maintenance and security review. Do not promise every application will be supported.

---

## 5. Vampire Security Toolkit

### 5.1 Purpose

Provide a first-party security workspace inspired by the breadth and organization of professional Linux security toolkits, while preserving Vampire OS independence and a small default footprint.

### 5.2 Tool categories

- Network discovery and diagnostics.
- Packet capture and protocol analysis.
- DNS, TLS and certificate inspection.
- Web application security testing.
- Vulnerability assessment and configuration auditing.
- Password-strength auditing and credential hygiene.
- Digital forensics and disk analysis.
- Reverse engineering and binary inspection.
- Malware analysis in isolated lab environments.
- Cryptography, key management and secure file handling.
- Firewall, host hardening and intrusion detection.
- Wireless security assessment for authorized lab networks.
- Container and cloud configuration auditing.

### 5.3 Installation and safety policy

- Install tools on demand through VPM; do not preload the entire catalogue.
- Group tools into **Essential**, **Advanced**, and **Lab** collections.
- Mark tools that can disrupt networks, modify systems, or access sensitive data.
- Require explicit user acknowledgement before installing or launching high-impact lab tools.
- Provide isolated lab profiles, disposable VMs/containers where available, and safe sample environments.
- Include legal/authorization reminders in the security workspace.
- Do not enable stealth, persistence, credential theft, or offensive actions by default.
- Keep security tools updated and identify their upstream source, license and maintainer.

The toolkit is for systems the user owns or is explicitly authorized to assess. It is not a replacement for security expertise or a guarantee that a host is secure.

---

## 6. Vampire Server Edition

### 6.1 Server goals

Vampire Server is a lightweight, headless-first edition. It must be manageable entirely over SSH and should not require a graphical desktop. An optional web administration panel can be installed separately.

### 6.2 Server management capabilities

- Hostname, users, groups and SSH key administration.
- CPU, memory, storage, disk health and network monitoring.
- Service start/stop/restart/enable/disable and logs.
- Firewall rules and open-port overview.
- Network interfaces, routes, DNS and static IP configuration.
- Storage mounts, RAID/LVM support where implemented, SMART health.
- Package updates, security updates and rollback status.
- Backup scheduling, restore verification and retention.
- Web server, database, cache, runtime and container management.
- TLS certificates and renewal status.
- Resource limits, process monitoring and system diagnostics.
- Audit events and administrator activity.
- Hardware and driver inventory.

The server edition should not ship every service enabled. Administrators install only the roles they need.

### 6.3 Server profiles / roles

Offer optional role bundles:

- Web Server.
- Database Server.
- Game Server.
- Storage / Backup Server.
- Container Host.
- Network Utility Server.
- Development / CI Runner.
- Monitoring Node.
- Security Lab Host.

Each profile is a package group and documented configuration preset, not a monolithic image that enables every daemon.

---

## 7. Vampire Fleet — manage multiple servers from one PC

### 7.1 Goal

A user should be able to manage many remote servers from one Vampire Desktop workstation, including servers running Vampire Server and supported Linux hosts.

### 7.2 Fleet interface

- Add host by IP address or DNS name.
- Save a named host profile with tags, environment and notes.
- Organize hosts into groups such as Production, Testing, Game Nodes and Storage.
- Show connection state, uptime, CPU, memory, disk, load and security/update status.
- Open terminal sessions to an individual host.
- Open multiple host sessions in tabs or tiled panes.
- Browse and transfer files to/from a selected host.
- Run approved commands against one host or a selected group.
- Deploy a package or update to a selected set of hosts with staged rollout.
- View service state and logs per host.
- Compare host inventory and package versions.
- Export/import encrypted host profiles.

### 7.3 Connection and security model

- SSH is the primary management transport for server administration.
- Verify and pin SSH host keys; warn on unexpected host-key changes.
- Prefer SSH keys or hardware-backed credentials; support agent forwarding only with explicit opt-in.
- Store secrets in an encrypted credential store; never plaintext config files.
- Support per-host identity, least privilege and optional MFA through supported authentication mechanisms.
- Use signed task definitions and show the exact command/target list before bulk execution.
- Require elevated confirmation for destructive or fleet-wide actions.
- Maintain an auditable history of operator, host, action, result and timestamp.
- Provide cancellation and staged rollout; never silently run a destructive command across all servers.
- Do not require a proprietary cloud relay. Direct LAN/VPN/SSH management should work.

A single PC should be able to manage separate servers independently: each host gets its own connection profile, terminal, file-transfer target, credentials and status.

---

## 8. Vampire Remote Desktop (RDP Mode)

### 8.1 User experience

- High Quality, Balanced and Low Bandwidth presets.
- Adaptive resolution, scaling, bitrate and frame rate.
- Hardware video encoding when supported, software fallback otherwise.
- Multi-monitor and HiDPI support.
- Smooth keyboard and pointer input.
- Optional audio playback and microphone redirection.
- Clipboard and file transfer as independent permission toggles.
- Session reconnect, lock, disconnect and administrator timeout.
- Connection indicator showing encryption, identity and quality.

### 8.2 Security baseline

- Disabled or localhost/private-interface-only by default.
- Recommend VPN/private overlay rather than direct public RDP exposure.
- Modern TLS, certificate validation and secure protocol configuration.
- Strong user authentication, optional MFA, rate limiting and account lockout.
- No remote root login by default.
- Per-user authorization and session isolation.
- Device, drive, clipboard and audio redirection disabled until explicitly allowed.
- Auditable authentication and session logs.
- Immediate session revocation and emergency service disable.
- Security updates and version visibility.

Use maintained upstream remote desktop components after compatibility and security review. Do not invent a custom cryptographic protocol.

---

## 9. Installer, boot and first-run experience

### 9.1 Editions

- Desktop ISO: graphical installer, desktop session and curated core apps.
- Server ISO: text-first installer, minimal services and optional admin panel.
- Rescue image: recovery, diagnostics, filesystem repair and backup restore tools.

### 9.2 Installer workflow

1. Boot and hardware compatibility check.
2. Choose Desktop, Server or Rescue environment.
3. Select language, keyboard and timezone.
4. Network configuration.
5. Disk selection, partitioning and optional full-disk encryption.
6. Create a non-root administrator account.
7. Review packages, bootloader and security settings.
8. Install and verify system.
9. Reboot into first-run setup.
10. Check updates and show recommended next steps.

Never erase or repartition a disk without a clear, explicit confirmation.

### 9.3 First boot

- Welcome screen and accessibility options.
- Network and update check.
- Theme and wallpaper choice.
- User security recommendations.
- Optional driver and firmware discovery.
- Software Center introduction.
- Server edition: SSH setup, firewall summary and management endpoint instructions.

---

## 10. Lightweight engineering principles

- Keep the base image small and boot services minimal.
- Install GUI, security suites, server roles and remote desktop as optional components.
- Measure cold boot, idle RAM, CPU wakeups, disk footprint and application launch time.
- Avoid mandatory background telemetry; diagnostics sharing must be opt-in.
- Prefer upstream maintained components over unnecessary custom rewrites.
- Use hardware acceleration when available but retain a functional software fallback.
- Make visual effects configurable and provide a reduced-effects mode.
- Support x86_64 first; other architectures require separate hardware and package validation.
- Use a non-systemd-dependent service architecture consistent with Vampire Init direction.
- Build in reproducible stages and publish checksums, signatures, SBOM and known issues.

---

## 11. Proposed technical architecture

This is a component-selection direction, not a locked dependency list. Each upstream component needs license, maintenance, security and compatibility review before adoption.

| Layer | Responsibility |
|---|---|
| Boot | UEFI, bootloader, kernel, initramfs |
| Kernel | Upstream Linux with reviewed Vampire configuration |
| Base userland | Independently built toolchain, libc and core utilities |
| Init / services | Vampire Init and service supervision |
| Package system | VPM, signed repositories, build recipes |
| Hardware | Device discovery, firmware policy, graphics/audio/network stack |
| Desktop session | Wayland-first compositor with compatibility strategy |
| Desktop shell | Vampire panel, launcher, settings and window UX |
| Applications | Vampire Files, Terminal, Monitor, Software Center |
| Security | Accounts, firewall, sandboxing, audit, update trust |
| Remote access | RDP service/client and SSH-based fleet manager |
| Server admin | CLI-first tools and optional web control plane |

Do not lock the desktop to a heavyweight full desktop environment just to get a familiar UI. Evaluate compositor, panel, toolkit and display stack independently.

---

## 12. Delivery roadmap and acceptance gates

### Phase 0 — Build foundation
- Reproducible cross-toolchain and source manifest.
- Minimal root filesystem and init.
- QEMU boot and serial-console test.
- Kernel/initramfs build verification.

**Gate:** repeatable build with documented hashes and successful QEMU boot.

### Phase 1 — Base OS
- Device management, logging, networking, users and service supervision.
- Filesystem layout, package database foundation and recovery shell.

**Gate:** usable CLI system with persistent storage and networking.

### Phase 2 — VPM and repository
- Repository generator, package builder and signing workflow.
- File ownership, dependency solver, atomic transaction and rollback.
- Initial official package set.

**Gate:** install, update, remove and recover test packages safely in a disposable VM.

### Phase 3 — Desktop foundation
- Display server/compositor, login, panel, Vampire Button and window management.
- Vampire Terminal, Files, Settings and wallpaper support.

**Gate:** stable daily-use session in QEMU and supported physical hardware.

### Phase 4 — Software Center and security workspace
- GUI catalogue connected to VPM.
- Curated security collections and isolation profiles.

**Gate:** install/uninstall/update GUI apps with trust and permission visibility.

### Phase 5 — Server Edition and Vampire Fleet
- Headless server profile, service manager, monitoring and secure SSH admin.
- Multi-host dashboard, terminal tabs, file transfer and staged updates.

**Gate:** manage multiple disposable test servers without plaintext secrets or unverified host keys.

### Phase 6 — RDP Mode
- Secure remote session, quality presets, multi-monitor, audio and permissions.

**Gate:** security tests plus LAN and constrained-network performance benchmarks.

### Phase 7 — Installer and release engineering
- Desktop/server/rescue images, Secure Boot plan, disk encryption and recovery.
- Hardware matrix, SBOM, signatures and release notes.

**Gate:** release candidate passes installation, upgrade, rollback, security and hardware test suites.

---

## 13. Quality, performance and security acceptance criteria

Before a feature is declared complete:

- It has automated tests and documented manual test steps.
- It handles permission errors and interrupted operations safely.
- It does not leak credentials or private data into logs.
- It supports keyboard navigation and readable contrast.
- It has a low-resource mode or documented resource requirements.
- It has an update and rollback story.
- It has a threat model for network-facing or privileged components.
- It is tested in a disposable VM before being used on real systems.

Security features are not marketing claims: publish what is implemented, what is tested, and what remains unsupported.

---

## 14. Initial application and package examples

Illustrative package names only; each package must be created, reviewed and added to the official repository before it can be installed.

```sh
vpm update
vpm search browser
vpm install vfetch -y
vpm install git curl wget -y
vpm install vampire-files
vpm install vampire-terminal
vpm install vampire-monitor
vpm install vampire-security-network-tools
vpm install vampire-server-admin
```

The command interface is a target. The current VPM prototype does not yet implement all these operations or package names.

---

## 15. Current project reality and non-goals

The Git repository currently contains experimental scaffolding, documentation, a custom fetch utility and an early Python VPM prototype. It is not yet a bootable, production-ready OS. Desktop shell, Software Center, complete package repository, Server Edition tools, Fleet manager, RDP implementation, installer and production security controls remain future engineering work.

Do not describe a feature as available until code exists, tests pass and its acceptance gate is met.

### Not in initial scope

- Shipping every security tool preinstalled.
- Making the desktop a full-screen Windows clone.
- Exposing remote desktop directly to the public internet by default.
- Running all server roles and daemons on a minimal server install.
- Supporting every architecture and GPU in the first release.
- Claiming perfect security or compatibility.

---

## 16. Open decisions for the next blueprint revision

These choices can be decided later without blocking the foundation:

- Preferred default desktop layout and taskbar alignment.
- Whether the Server web panel is local-only, SSH-tunneled, or optionally network-exposed.
- First supported GPU vendors and hardware matrix.
- Official repository hosting and package mirror strategy.
- Exact RDP upstream implementation after technical review.
- First release's default application set and minimum hardware requirements.
- Whether Vampire Fleet ships as a Desktop app only or also as a separate admin workstation image.

**Guiding rule:** build a genuinely independent, lightweight Linux system first; layer Vampire-branded desktop, software, security and server experiences on top of a reliable and auditable foundation.
