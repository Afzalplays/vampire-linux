# Signed update metadata and download MVP

The development image includes `vupdate`:

- `vupdate check` downloads a manifest and detached signature over HTTPS,
  verifies Minisign, and validates channel, architecture, version, artifact
  URL, size and SHA-256 metadata.
- `vupdate download` repeats signature verification, downloads the image,
  checks exact size and SHA-256, then atomically stages it in
  `/var/cache/vampire/updates`.
- `vupdate status` lists locally staged images.

The shipped `/etc/vampire/update.json` has no endpoint or public key because
there is no production Vampire release service yet. Configure a trusted HTTPS
manifest URL, signature URL and independently verified Minisign public key.

**Applying updates is not implemented.** The current live system has no
verified A/B system slots, boot-success marker, recovery partition or rollback
controller. Downloading an image is not an update installation. Do not
overwrite the running root filesystem or boot media with this prototype.
