# Vampire Shell

Vampire Shell is the branded interactive command-line environment for Vampire
OS. The first implementation is a Bash-compatible shell profile and launcher,
not a new shell parser or independent command interpreter.

## Usage

```sh
vsh
vsh --version
vsh -c 'vfetch && vhealth'
```

The launcher loads `/etc/vampire/shellrc`, enables a restrictive umask,
configures bounded command history, and applies a crimson prompt in interactive
sessions. The shell profile is automatically included in both live-image
editions through the root filesystem overlay.

## Execution engine and limitations

Bash remains the command execution engine in this milestone. Existing POSIX
`/bin/sh` scripts continue to use the system's BusyBox shell. Vampire Shell
does not yet provide its own parser, completion engine, scripting language,
plugin system, or graphical terminal application. Do not describe this
compatibility layer as an independently implemented shell.
