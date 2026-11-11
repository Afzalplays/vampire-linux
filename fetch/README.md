# Vampire Fetch

Vampire Fetch (`vfetch`) is the project's custom Bash-based Linux system
information display. It runs on Vampire OS and common Linux development hosts.

## Run

```sh
chmod +x fetch/vfetch
./fetch/vfetch
```

## Install locally

```sh
sudo install -Dm755 fetch/vfetch /usr/local/bin/vfetch
vfetch
```

It detects OS release metadata, hostname, kernel, architecture, shell, terminal,
desktop session, CPU, GPU (when `lspci` is available), memory, package count,
uptime, and local IP.

Set `VAMPIRE_EDITION` and `VAMPIRE_VERSION` to override displayed release
metadata. This is an early utility; detection fallbacks and tests will improve
as the base operating system develops.
