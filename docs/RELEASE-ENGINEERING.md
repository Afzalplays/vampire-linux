# Release engineering

An ISO is not publishable merely because the build command exits successfully.

Required release gates:
1. Clean build from pinned upstream sources.
2. Verify source archives and toolchain inputs.
3. Run shell, Python, configuration and package metadata tests.
4. Boot in QEMU BIOS and UEFI modes.
5. Verify console login, VFetch, networking, reboot and shutdown.
6. Generate and verify ISO checksums.
7. Review licensing, SBOM, release notes and security contact.
8. Run physical hardware tests before publishing compatibility claims.

Development images are for testing, not stable or production use. Stable
releases additionally require signed release metadata and independently
published signing-key fingerprints.
