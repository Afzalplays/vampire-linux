# Vampire SSH service — opt-in public-key mode

The live image includes Dropbear client/server tools, but **the SSH daemon is
not started automatically**.

Before starting the server, place a trusted modern public key in
`/root/.ssh/authorized_keys`, then run:

```sh
mkdir -p /root/.ssh
chmod 700 /root/.ssh
# Add your ssh-ed25519 public key to /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
vssh start
vssh status
```

The service refuses to start without an authorized key. It disables password
authentication and root password authentication. The default port is 22;
override it with `VAMPIRE_SSH_PORT=2222 vssh start`. To stop the service, run
`vssh stop`. The SSH client is available through `vssh connect user@host`.

The Ed25519 host key is stored at `/var/lib/vampire/ssh/dropbear_ed25519_host_key` by default; override it with `VAMPIRE_SSH_HOST_KEY` if required. It persists across reboot only when `/var` is on persistent storage. In the current initramfs live session, `/var` is temporary, so the host key changes after reboot.

This remains an opt-in development/live-session service, not a finished server
edition. Production deployments still need non-root user onboarding, firewall
integration, audit logging and a tested persistent filesystem. Do not expose
this live image to an untrusted network.
