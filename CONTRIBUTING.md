# Contributing to Vampire OS

Vampire OS is experimental systems software. Contributions should be
reviewable, reproducible, and explicit about what has and has not been tested.

Before contributing:

- Read the architecture and licensing documents.
- Keep the target independent of existing Linux distributions. A host distro
  may provide build tools, but must not become the target root filesystem.
- Pin upstream versions and verify source archives.
- Preserve upstream copyright and license notices.
- Never commit credentials, private keys, tokens, or personal data.

Pull requests should explain the change, exact build/test commands, host
architecture and tool versions, results and limitations, and provenance/license
details for added third-party material.

Do not describe an untested image as bootable or a placeholder subsystem as
implemented.
