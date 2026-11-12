# Vampire OS roadmap

A feature is complete only after implementation, automated tests, and relevant
runtime validation. A design document or build script alone does not make a
feature release-ready.

## 0.1 developer live environment

- [x] Define an independent x86_64 distribution target.
- [x] Add musl, BusyBox init, Linux kernel and Buildroot image configuration.
- [x] Add VFetch, GRUB hybrid ISO builder and SHA-256 generation.
- [x] Add VPM experimental client, signed-index verification and unit tests.
- [x] Add shell/configuration CI checks and QEMU BIOS/UEFI smoke-test script.
- [x] Add initial service dispatcher, DHCP helper and opt-in nftables helper.
- [x] Add validated settings storage and an interactive console launcher.
- [x] Add read-only installer disk discovery and target preflight checks.
- [x] Build desktop and server ISO images in CI.
- [ ] Pass QEMU BIOS and UEFI boot tests; current BIOS passes but OVMF UEFI test is being corrected.
- [ ] Verify VFetch, DHCP, reboot and shutdown inside both images.
- [ ] Publish checksum-verified developer ISO artifacts after boot tests pass.

## Core operating system

- [ ] Pin and verify source archives and toolchain inputs.
- [ ] Establish reproducible builds and build provenance.
- [ ] Build a dedicated cross-toolchain and stable filesystem layout.
- [ ] Implement a production service supervisor, users, groups, logging and device management.
- [ ] Complete network profiles, DNS, Wi-Fi and VPN support.
- [ ] Add firmware handling and a tested rescue mode.

## Package management

- [x] Experimental VPM CLI, signed metadata and payload hash verification.
- [x] Dependency resolution, architecture checks and guarded extraction.
- [ ] Reproducible package recipes and maintained signed repository.
- [ ] Transactional install/upgrade, rollback and recovery.
- [ ] Configure a maintained signed repository and integrate VPM into installation.
- [ ] Build graphical Vampire Software Center.

## Desktop edition

- [x] Add Weston DRM/Wayland compositor and upstream desktop-shell packages for graphics bring-up.
- [x] Add console launcher and validated settings backend.
- [x] Add console file manager, hardware inventory and diagnostics.
- [ ] Build the branded Vampire Desktop shell: top panel, floating dock, launcher and window integration.
- [ ] Add non-root graphical login/session management.
- [ ] Build graphical file manager, terminal and settings applications.
- [ ] Add display, network, sound, power, accessibility and voice controls.
- [ ] Validate audio, Bluetooth, printing, touchpads and multi-monitor support.

## Installer and recovery

- [x] Read-only disk inventory and installation preflight.
- [ ] Build guided text installer for Server and graphical installer for Desktop.
- [ ] Implement safe partitioning, filesystems, UEFI/BIOS bootloader installation and confirmation gates.
- [ ] Add encrypted installation, recovery media, boot repair and tested restore workflow.

## Server edition

- [x] Add a separate console-first Server Buildroot configuration and ISO workflow.
- [x] Add opt-in Dropbear SSH prototype and service controls.
- [x] Add monitoring, network, storage and hardware diagnostics.
- [ ] Add persistent SSH host keys, non-root onboarding and hardened defaults.
- [ ] Build multi-host administration, file transfer, deployment and recovery.
- [ ] Integrate secure remote desktop and VPN-only access controls.

## Security and updates

- [x] Add firewall helper and signed update-manifest verification prototype.
- [ ] Configure production signing keys, trust rotation and maintained update metadata.
- [ ] Implement atomic OS/application update application, history and rollback.
- [ ] Implement Secure Boot signing, disk encryption and application isolation.
- [ ] Add audit logging, login protection, SBOM and vulnerability response.

## Stable release gates

- [ ] BIOS/UEFI validation on virtual and physical hardware.
- [ ] Install to a blank virtual disk, reboot from installed disk and test recovery.
- [ ] Hardware compatibility and accessibility test matrix.
- [ ] Reproducible signed artifacts, notices and release notes.

The current repository is a developer-stage live environment, not a finished
desktop operating system or production installer. Do not label a feature
release-ready until its implementation and tests are complete.
