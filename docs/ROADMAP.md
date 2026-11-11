# Vampire OS roadmap

A feature is complete only after implementation, automated tests, and relevant
runtime validation. A design document or build script alone does not make a
feature release-ready.

## 0.1 Developer live environment

- [x] Define an independent x86_64 distribution target.
- [x] Add musl, BusyBox init, Linux kernel and Buildroot image configuration.
- [x] Add VFetch, GRUB hybrid ISO builder and SHA-256 generation.
- [x] Add VPM experimental client, signed-index verification and unit tests.
- [x] Add shell/configuration CI checks and QEMU BIOS/UEFI smoke-test script.
- [x] Add initial service dispatcher, DHCP helper and opt-in nftables helper.
- [x] Add validated settings storage and an interactive console launcher MVP.
- [x] Add isolated tests for settings validation and desktop launcher syntax.
- [ ] Complete a clean live ISO build and retain its artifact.
- [ ] Pass QEMU BIOS and UEFI boot tests and verify console login.
- [ ] Verify VFetch, DHCP, reboot and shutdown inside the image.
- [ ] Publish a checksum-verified developer ISO.

## Core operating system

- [ ] Pin and verify source archives and toolchain inputs.
- [ ] Establish reproducible builds and build provenance.
- [ ] Build a dedicated cross-toolchain and stable filesystem layout.
- [ ] Implement a real Vampire Init supervisor.
- [ ] Implement users, groups, permissions, logging and device management.
- [ ] Complete network profiles, DNS, Wi-Fi and VPN support.
- [ ] Add hardware discovery, firmware handling and rescue mode.

## Package management

- [x] Experimental VPM CLI, signed metadata and payload hash verification.
- [x] Dependency resolution, architecture checks and guarded extraction.
- [ ] Reproducible package recipes and maintained signed repository.
- [ ] Transactional install/upgrade, rollback and recovery.
- [ ] Integrate VPM into root filesystem and graphical installer.
- [ ] Build Vampire Software Center.

## Desktop edition

- [ ] Wayland compositor, display manager and graphical Vampire Desktop shell.
- [x] Console-mode `vdesktop` launcher and `vsettings` preference backend (bring-up tools only).
- [ ] Original top panel, floating dock, launcher and window management.
- [ ] File manager, terminal and settings application.
- [ ] Display, network, sound, power and personalization controls.
- [ ] Audio, Bluetooth, printing, accessibility and voice access.
- [ ] Graphical installer and first-boot experience.

## Server edition

- [ ] Headless install profile, SSH onboarding and hardened defaults.
- [ ] Multi-host administration, SSH terminal and file transfer.
- [ ] Monitoring, service control, deployment and recovery.
- [ ] Secure remote desktop integration and session controls.

## Security and updates

- [ ] Signed OS and application update pipeline.
- [ ] Atomic updates, history, rollback and recovery.
- [ ] Secure Boot signing, disk encryption and application isolation.
- [ ] Audit logging, login protection and firewall policy management.
- [ ] Curated optional security tools, SBOM and vulnerability response.

## Stable release gates

- [ ] BIOS/UEFI validation on virtual and physical hardware.
- [ ] Graphical installer, partitioning, reinstall and recovery tests.
- [ ] Hardware compatibility and accessibility test matrix.
- [ ] Reproducible signed artifacts, notices and release notes.

A development image is not a stable release. Production readiness requires all
relevant release gates to pass.
