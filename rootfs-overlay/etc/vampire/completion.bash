# Vampire OS command completion for the Bash-compatible Vampire Shell.
# This file only registers static, non-executing completions; it never runs a
# partially typed command or reads credentials from the environment.

_vampire_complete() {
  local command_name="${COMP_WORDS[0]##*/}"
  local current="${COMP_WORDS[COMP_CWORD]}"
  local previous=""
  local candidates=""

  if (( COMP_CWORD > 0 )); then
    previous="${COMP_WORDS[COMP_CWORD-1]}"
  fi

  case "$command_name" in
    vpower)
      candidates="status reboot poweroff halt --yes --help"
      ;;
    vsettings)
      case "$previous" in
        get|set) candidates="theme accent surface_transparency blur terminal_opacity dock_size dock_position dock_auto_hide dock_magnification top_panel show_date show_clock show_network show_power reduced_motion update_channel voice_access" ;;
        *) candidates="keys list get set apply bootstrap --help" ;;
      esac
      ;;
    vnetwork)
      case "$previous" in
        wifi) candidates="list scan connect status disconnect" ;;
        *) candidates="status wifi start stop --help" ;;
      esac
      ;;
    vctl)
      candidates="list status status-all start stop restart enable disable --help"
      ;;
    vpm)
      candidates="install remove update list search doctor --help"
      ;;
    vlauncher)
      candidates="--help --search"
      ;;
    vdisplay)
      candidates="--help"
      ;;
    vinstall)
      candidates="requirements system-check media list preflight plan install validate --help"
      ;;
    vssh)
      candidates="status keys enable disable --help"
      ;;
    vsoftware)
      candidates="list search install remove update --help"
      ;;
    vfetch|vhelp|vmonitor|vdesktop|vgraphical)
      candidates="--help"
      ;;
    *)
      return 0
      ;;
  esac

  COMPREPLY=( $(compgen -W "$candidates" -- "$current") )
}

for _vampire_command in \
  vpower vsettings vnetwork vctl vpm vlauncher vdisplay vinstall \
  vssh vsoftware vfetch vhelp vmonitor vdesktop vgraphical
do
  complete -o bashdefault -o default -F _vampire_complete "$_vampire_command"
done
unset _vampire_command
