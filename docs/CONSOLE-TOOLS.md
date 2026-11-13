# Vampire console tools

These commands are included in the early x86_64 live image. They are console
bring-up tools; they do not claim to be the finished graphical Vampire Desktop.

## Launch the console desktop menu

```sh
vdesktop
```

The console launcher opens system information, appearance preferences, network status, a system monitor, Vampire Shell, installer preflight, the Weston preview, VPM diagnostics, update checks, Software Center, SSH status, Files, hardware inventory, health checks, support snapshots, firewall status and the command reference. It is keyboard-driven and exits without modifying disks.

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

`vsettings apply` generates runtime Weston and Foot configuration from the validated
preferences. Theme, accent, panel visibility, panel transparency, reduced motion
and terminal opacity are applied when the graphical session next starts. Blur,
dock size/position/auto-hide, voice access and update-channel preferences remain
stored settings only; they are not yet connected to a compositor feature, speech
service or update service.

## Network and service tools

```sh
vnetwork status
vnetwork start eth0
vnetwork stop eth0
vnetwork wifi list
vnetwork wifi scan wlan0
vnetwork wifi connect wlan0 'Home Wi-Fi'
vnetwork wifi status wlan0
vnetwork wifi disconnect wlan0
vctl list
vctl status network
vctl status-all
vctl start network
```

The console Desktop also includes a Service Manager menu for listing, inspecting, starting, stopping, restarting and changing boot enablement. Bulk operations preserve configured service order, with shutdown performed in reverse.\n\nDHCP startup is attempted during live boot. The DHCP hook configures the IPv4
address, default route and DNS resolver from a validated lease. Stopping the
network service removes only resolver data written by Vampire DHCP. The firewall helper remains
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

- `vgraphical` starts the configured Weston DRM desktop preview when a DRM GPU is available.
  The preview includes Foot with Vampire Shell and panel launchers for Terminal, Files,
  Settings and Software Center. It is not yet the custom Vampire shell; see
  [GRAPHICAL-SESSION.md](GRAPHICAL-SESSION.md).
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

## Command reference

Run `vhelp` from Vampire Shell or choose option 18 in `vdesktop` for the complete command list and safety notes.

Wi-Fi uses `iw` and `wpa_supplicant`. The connection command prompts for a WPA passphrase without echoing it and stores only the derived PSK in a mode-0600 configuration file. The Desktop image includes common Intel iwlwifi firmware; other adapters still depend on their kernel driver and firmware being available.
