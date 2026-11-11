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

This is an opt-in development/live-session service, not a finished server
edition. Host keys are generated locally and are ephemeral in the current
read-only initramfs session; production server deployments need persistent
per-device host keys, non-root user onboarding, firewall integration,
audit logging and a tested persistent filesystem. Do not expose this live
image to an untrusted network.
