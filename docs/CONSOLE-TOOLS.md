# Vampire console tools

These commands are included in the early x86_64 live image. They are console
bring-up tools; they do not claim to be the finished graphical Vampire Desktop.

## Launch the console desktop menu

```sh
vdesktop
```

The menu currently opens system information, the appearance preference menu,
network status, a read-only system monitor, a shell and a read-only installer storage preflight. The appearance menu also exposes the stable/testing update channel and voice-access preference. These are stored preferences only; enabling voice access does not start a microphone or speech service. It is keyboard-driven and exits without modifying the host or disk.

## Manage preferences

```sh
vsettings list
vsettings validate
vsettings get theme
vsettings set theme dark
vsettings set blur medium
vsettings set terminal_opacity 90
vsettings reset
```

Allowed values are deliberately constrained:

| Key | Values |
|---|---|
| `theme` | `dark`, `light`, `system` |
| `blur` | `off`, `low`, `medium`, `high`, `extreme` |
| `terminal_opacity` | `0` through `100`, in steps of 10 |
| `dock_size` | `small`, `medium`, `large` |
| `reduced_motion` | `true`, `false` |
| `update_channel` | `stable`, `testing` |
| `voice_access` | `true`, `false` |

The live environment seeds `/etc/vampire/settings.conf` from
`/etc/vampire/settings.defaults` on first boot. The config is stored with
owner-only permissions. `vsettings validate` rejects malformed lines, unknown keys,
invalid values and duplicate keys without sourcing the file as shell code. For tests,
set `VAMPIRE_SETTINGS_FILE` to a temporary path.

**Important:** These are stored preferences only. Blur, opacity, dock size,
voice access and update-channel preferences are not yet connected to a
graphical compositor, speech service or update service. No graphical panel,
dock, file manager, window manager or installer is included yet.

## Network and service tools

```sh
vnetwork status
vctl list
vctl status network
vctl start network
```

DHCP startup is attempted during live boot. The firewall helper remains
opt-in because applying an inbound-drop policy can disconnect a remote server:

```sh
VAMPIRE_SSH_PORT=22 vguard apply
vguard status
vguard clear
```

Review the firewall rules and verify remote access before applying them on a
remote machine.


## Installer storage preflight

From the console launcher choose option 7, or run:

```sh
vinstall list
vinstall preflight /dev/sda
```

This only inspects sysfs and mounted partitions. It never partitions, formats or
writes to storage. A passing preflight is not approval to erase a disk.


## Graphical preview and package manager

- `vgraphical` starts the upstream Weston DRM desktop shell when a DRM GPU is available.
  This is not the branded Vampire Desktop; see [GRAPHICAL-SESSION.md](GRAPHICAL-SESSION.md).
- `vpm --version`, `vpm list` and `vpm doctor` are included in the image.
  The repository list is empty until a signed Vampire package repository exists;
  see [VPM-INTEGRATION.md](VPM-INTEGRATION.md).


## SSH service

The image includes Dropbear client/server tools. The daemon is not auto-started.
Run `vssh status` to inspect it. To start it, first place a trusted modern
public key in `/root/.ssh/authorized_keys`, then use `vssh start`.
Password authentication is disabled. See [SSH-ONBOARDING.md](SSH-ONBOARDING.md).


## Diagnostics and firewall

Run `vhardware`, `vstorage`, `vhealth`, `vlogs` or `vdiagnose` for
read-only hardware, storage, health and support information. Review and redact
`vdiagnose` output before sharing; logs and device details may be sensitive.

The optional nftables profile is managed by `vfirewall status|apply|clear`.
It is not enabled at boot. Applying a default-deny inbound policy remotely
can disconnect you; verify the SSH port and recovery access first. See
[HARDWARE-DIAGNOSTICS.md](HARDWARE-DIAGNOSTICS.md) and [FIREWALL.md](FIREWALL.md).
