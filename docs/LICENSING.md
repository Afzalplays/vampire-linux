# Licensing and third-party source policy

The root project license applies only to original project files that carry that
license notice. It does not relicense Linux, BusyBox, musl, GRUB, or any other
upstream dependency.

Before distributing a build, maintainers must:

1. Record each shipped component, exact version, source URL, and checksum.
2. Verify upstream signatures where provided.
3. Preserve copyright, license, and attribution notices.
4. Provide corresponding source and written offers where required.
5. Track local patches and publish corresponding source.
6. Generate a software bill of materials (SBOM) for each release.

Expected license families (verify the exact selected version and modules):

- Linux kernel: generally GPL-2.0-only, with separately licensed components.
- BusyBox: GPL-2.0-only.
- musl: MIT.
- GNU GRUB: GPL-3.0-or-later for relevant components.

Do not assume one component's license applies to the whole OS. Review firmware,
fonts, codecs, and other assets separately before redistribution. Use SPDX
identifiers in source headers and ship third-party notices with releases.
