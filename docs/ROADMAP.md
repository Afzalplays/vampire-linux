# Vampire OS roadmap

Status rule: a feature is complete only after its implementation has passed
relevant automated tests and runtime validation. Documentation or a build
script alone does not make a feature release-ready.

## Current release target: 0.1.0-dev live bring-up

- [x] Define independent-distribution scope (Buildroot is the build system, not the runtime base)
- [x] Establish x86_64 as the first target
- [x] Add initial Vampire Fetch utility
- [x] Add a minimal musl + BusyBox + Linux kernel Buildroot configuration
- [x] Add a GRUB hybrid ISO packaging script and SHA-256 generation
- [x] Add CI checks for build-script syntax and required configuration
- [ ] Complete the first automated live ISO build
- [ ] Boot the ISO in QEMU in BIOS mode and capture serial/console output
- [ ] Boot the ISO in QEMU in UEFI mode and capture serial/console output
- [ ] Validate the live console, init sequence, VFetch, networking and shutdown
- [ ] Publish the first downloadable development ISO and checksum

## Core operating system

- [ ] Pin and verify upstream source archives and toolchain inputs
- [ ] Establish reproducible clean builds and build provenance
- [ ] Build a dedicated cross-toolchain (Binutils, GCC, musl)
- [ ] Implement Vampire Init, service supervision, device management and logging
- [ ] Implement users, groups, permissions and filesystem layout
- [ ] Implement network configuration and DNS management
- [ ] Add hardware discovery and firmware handling
- [ ] Add crash recovery, rescue shell and boot repair

## Vampire Package Manager (VPM)

- [x] Prototype CLI commands: update, search, info, list, install and remove
- [x] Verify signed repository metadata and package SHA-256 payloads
- [x] Add dependency resolution, architecture checks and guarded archive extraction
- [x] Add basic installed-file ownership tracking and removal tests
- [ ] Add real package recipes built from pinned upstream source
- [ ] Publish and operate a signed package repository with production keys
- [ ] Add transactional install/upgrade, rollback and recovery
- [ ] Add safe shared-file/directory ownership and configuration-file handling
- [ ] Integrate VPM into the live/root filesystem and installer
- [ ] Build a graphical Vampire Software Center

## Vampire Server edition

- [ ] Minimal server installation profile
- [ ] SSH setup, firewall defaults and secure first-boot configuration
- [ ] Service management and headless administration
- [ ] Multi-server SSH dashboard, file transfer and monitoring
- [ ] Server hardening and recovery guide
- [ ] RDP server/client integration with secure session defaults

## Vampire Desktop edition

- [ ] Graphics stack, compositor and display manager
- [ ] Vampire Desktop shell, launcher, floating dock and top system panel
- [ ] File manager, terminal and branded application launcher
- [ ] Settings app: display, network, sound, power and personalization
- [ ] Transparency/blur controls and theme integration
- [ ] Audio, Bluetooth, printing and power management
- [ ] Voice Access with supported speech models and confirmation for destructive actions
- [ ] Graphical installer and first-boot setup

## Updates and security

- [ ] Signed OS and application update pipeline
- [ ] Update history, rollback and recovery
- [ ] Firewall, login protection, audit logs and least-privilege defaults
- [ ] Secure Boot signing and verification
- [ ] Disk encryption and application isolation
- [ ] Curated optional security-tool packages
- [ ] SBOM, license notices and vulnerability response process

## Installer and release gates

- [ ] BIOS and UEFI boot validation on virtual and physical hardware
- [ ] Graphical installer with disk/partition handling and clear destructive-action confirmation
- [ ] Install, reboot, upgrade and recovery test matrix
- [ ] Hardware compatibility matrix and release notes
- [ ] Reproducible release artifacts, checksums and signed release metadata

A development ISO is not a stable release. Do not call Vampire OS stable until
clean builds are reproducible, boot and installation tests pass, update and
recovery paths are tested, security updates are documented, and licensing
notices are complete.
