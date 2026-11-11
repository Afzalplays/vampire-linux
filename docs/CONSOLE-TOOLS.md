# Vampire console tools

These commands are included in the early x86_64 live image. They are console
bring-up tools; they do not claim to be the finished graphical Vampire Desktop.

## Launch the console desktop menu

```sh
vdesktop
```

The menu currently opens system information, the appearance preference menu,
network status, a read-only system monitor and a shell. It is keyboard-driven and exits without modifying
the host or disk.

## Manage preferences

```sh
vsettings list
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
owner-only permissions. For tests, set `VAMPIRE_SETTINGS_FILE` to a temporary
path.

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
