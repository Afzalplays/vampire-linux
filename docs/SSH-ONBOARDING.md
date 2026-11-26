# Vampire SSH service — opt-in public-key mode

Dropbear is included in the Server edition, but **the SSH daemon is not started
automatically**. Password authentication is disabled and root SSH login is
blocked.

## 1. Authorize a regular user

The default local account is `vampire`. From the local root console, add the
client's **public** key (never copy a private key onto the server):

```sh
vssh authorize vampire 'ssh-ed25519 AAAA... your-device'
```

The command writes the key to `/home/vampire/.ssh/authorized_keys`, sets the
SSH directory to mode `0700` and the key file to `0600`, and refuses root
accounts, unsupported key types, and symlinked SSH paths. It is safe to repeat
the same key; duplicates are not added.

Supported key types: Ed25519, ECDSA P-256 and security-key Ed25519.

## 2. Start and verify the daemon

```sh
vssh start
vssh status
```

The default port is 22. Override it when starting the daemon with
`VAMPIRE_SSH_PORT=2222 vssh start`. The daemon is started with Dropbear's
password-authentication and root-login restrictions enabled. The Ed25519 host
key is stored at
`/var/lib/vampire/ssh/dropbear_ed25519_host_key` by default; override it with
`VAMPIRE_SSH_HOST_KEY` if required.

## 3. Connect from your client

```sh
ssh vampire@SERVER_IP
```

Stop the service locally with `vssh stop`. The SSH client is also available
through `vssh connect vampire@SERVER_IP`.

## Persistence and release limitations

The host key survives reboot only when `/var` is on persistent storage. The
live initramfs uses temporary storage, so its host key changes after reboot.
Installed-system host-key persistence still requires an end-to-end reboot
validation. This is a development-stage opt-in service, not a production
server-management stack. Do not expose the live image to an untrusted network.
