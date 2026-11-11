# Vampire OS roadmap

A checked-in script is not considered complete until it has tests and successful
build or runtime validation.

## Foundation

- [x] Define independent-distribution scope
- [x] Establish x86_64 as the first target
- [x] Add initial Vampire Fetch utility
- [ ] Add automated shell linting and fetch tests
- [ ] Pin and verify all Stage 0 upstream source archives
- [ ] Complete a reproducible Stage 0 build on a clean Linux build host
- [ ] Boot the generated image in QEMU and capture serial output
- [ ] Build a cross-toolchain (Binutils and GCC)
- [ ] Implement init, service supervision, device management, and logging
- [ ] Implement networking, users, groups, and filesystem layout

## Distribution infrastructure

- [ ] Specify package format and metadata
- [ ] Implement dependency resolution and package management
- [ ] Sign repository metadata and packages
- [ ] Create package build recipes and source mirrors
- [ ] Define update, rollback, and recovery
- [ ] Generate an SBOM for every release

## Editions

### Vampire Server
- [ ] Minimal installation profile
- [ ] SSH and firewall configuration
- [ ] Service management and headless administration
- [ ] Server hardening guide

### Vampire Desktop
- [ ] Graphics stack and display manager
- [ ] Vampire Desktop shell and settings
- [ ] Audio, Bluetooth, printing, and power management
- [ ] Graphical installer

## Release gates

Do not call a release stable until clean builds are reproducible, boot and
installation tests pass, upgrade/recovery paths are tested, security updates
are documented, and licensing notices are complete.
