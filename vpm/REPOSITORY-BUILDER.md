# Vampire repository builder

`repo_tool.py` creates a static repository directory containing an `index.json`
and copied package archives. It can sign the index using a locally held
Minisign secret key.

## Build a local test repository

Create a package archive with files stored relative to the target filesystem
root, then create a metadata JSON file. See
[`hello-vampire.json`](hello-vampire.json) for the metadata shape.

```sh
python3 vpm/repo_tool.py \
  --repository vampire-testing \
  --architecture x86_64 \
  --metadata vpm/hello-vampire.json \
  --output dist/repository
```

The output is a static directory that can be served by any HTTPS static-file
host. The unsigned mode is only for local inspection and testing. Never publish
an unsigned repository or configure production clients to trust it.

## Sign a release index

Keep the Minisign secret key outside the repository and outside build logs:

```sh
python3 vpm/repo_tool.py \
  --repository vampire-stable \
  --architecture x86_64 \
  --metadata packages/*.json \
  --output dist/stable \
  --signing-key /secure/path/vampire-repo.key
```

The builder invokes `minisign -S` to create `index.json.minisig`. Configure
the matching public key out-of-band in the client. Do not upload the secret
key to GitHub or a public build artifact.

## Metadata fields

Required: `name`, `version`, `description`, `architecture`, `license`,
`depends`, and local `archive` path. The generated index records the
relative archive URL and streaming SHA-256 digest. Package names and versions
are validated, duplicate names are rejected, and package architecture must
match the repository or be `any`.

This is an early static-index builder, not a complete package build system.
It does not yet compile upstream source, create reproducible archives, produce
SBOM/provenance, or validate package contents. Review packages before signing.
