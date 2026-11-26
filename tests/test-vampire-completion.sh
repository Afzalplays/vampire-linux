#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
COMPLETION="$ROOT/rootfs-overlay/etc/vampire/completion.bash"

complete_for() {
  local command_name="$1" prefix="$2" expected="$3" output
  output="$(bash --noprofile --norc -c '
    source "$1"
    COMP_WORDS=("$2" "$3")
    COMP_CWORD=1
    _vampire_complete
    printf "%s\n" "${COMPREPLY[@]}"
  ' bash "$COMPLETION" "$command_name" "$prefix")"
  grep -Fxq -- "$expected" <<<"$output" || {
    printf 'FAIL: %s completion for prefix %s omitted %s\n' "$command_name" "$prefix" "$expected" >&2
    printf 'Actual candidates:\n%s\n' "$output" >&2
    exit 1
  }
}

complete_nested() {
  local command_name="$1" previous="$2" prefix="$3" expected="$4" output
  output="$(bash --noprofile --norc -c '
    source "$1"
    COMP_WORDS=("$2" "$3" "$4")
    COMP_CWORD=2
    _vampire_complete
    printf "%s\n" "${COMPREPLY[@]}"
  ' bash "$COMPLETION" "$command_name" "$previous" "$prefix")"
  grep -Fxq -- "$expected" <<<"$output" || {
    printf 'FAIL: %s %s completion omitted %s\n' "$command_name" "$previous" "$expected" >&2
    printf 'Actual candidates:\n%s\n' "$output" >&2
    exit 1
  }
}

complete_value() {
  local command_name="$1" subcommand="$2" key="$3" prefix="$4" expected="$5" output
  output="$(bash --noprofile --norc -c '
    source "$1"
    COMP_WORDS=("$2" "$3" "$4" "$5")
    COMP_CWORD=3
    _vampire_complete
    printf "%s\n" "${COMPREPLY[@]}"
  ' bash "$COMPLETION" "$command_name" "$subcommand" "$key" "$prefix")"
  grep -Fxq -- "$expected" <<<"$output" || {
    printf 'FAIL: %s %s %s completion omitted %s\n' "$command_name" "$subcommand" "$key" "$expected" >&2
    printf 'Actual candidates:\n%s\n' "$output" >&2
    exit 1
  }
}

complete_for vpower r reboot
complete_for vlauncher --s --search
complete_for vinstall p preflight
complete_for vssh s status
complete_nested vsettings set d dock_auto_hide
complete_nested vnetwork wifi c connect
complete_nested vnetwork wifi a auto
complete_value vsettings set theme d dark

# Completion must be registered for supported tools and leave unknown commands alone.
bash --noprofile --norc -c '
  source "$1"
  complete -p vpower | grep -Fq "_vampire_complete"
  COMP_WORDS=(not-a-vampire-command h)
  COMP_CWORD=1
  _vampire_complete
  [[ ${#COMPREPLY[@]} -eq 0 ]]
' bash "$COMPLETION"

echo "Vampire Shell programmable completion tests passed."
