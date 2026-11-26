# Vampire OS command completion for the Bash-compatible Vampire Shell.
# This file only registers static, non-executing completions; it never runs a
# partially typed command or reads credentials from the environment.

_vampire_complete() {
  local command_name="${COMP_WORDS[0]##*/}"
  local current="${COMP_WORDS[COMP_CWORD]}"
  local previous=""
  local prior_previous=""
  local setting_key=""
  local candidates=""

  if (( COMP_CWORD > 0 )); then previous="${COMP_WORDS[COMP_CWORD-1]}"; fi
  if (( COMP_CWORD > 1 )); then prior_previous="${COMP_WORDS[COMP_CWORD-2]}"; fi

  case "$command_name" in
    vpower)
      candidates="status reboot poweroff halt --yes --help"
      ;;
    vsettings)
      if [[ "$prior_previous" == set ]]; then
        setting_key="$previous"
        case "$setting_key" in
          theme) candidates="dark light system" ;;
          accent) candidates="crimson rose ice violet" ;;
          surface_transparency) candidates="0 10 20 30 40 50 60" ;;
          blur) candidates="off low medium high extreme" ;;
          terminal_opacity) candidates="0 10 20 30 40 50 60 70 80 90 100" ;;
          dock_size) candidates="small medium large" ;;
          dock_position) candidates="bottom-center left-center right-center" ;;
          dock_auto_hide|dock_magnification|top_panel|show_date|show_clock|show_network|show_power|reduced_motion|voice_access) candidates="true false" ;;
          update_channel) candidates="stable testing" ;;
        esac
      elif [[ "$previous" == set || "$previous" == get ]]; then
        candidates="theme accent surface_transparency blur terminal_opacity dock_size dock_position dock_auto_hide dock_magnification top_panel show_date show_clock show_network show_power reduced_motion update_channel voice_access"
      else
        candidates="list keys get set validate reset apply --help"
      fi
      ;;
    vnetwork)
      case "$previous" in
        wifi) candidates="list scan status connect disconnect auto" ;;
        *) candidates="start stop restart status wifi --help" ;;
      esac
      ;;
    vctl)
      candidates="list start stop restart status status-all enable disable start-all stop-all --help"
      ;;
    vpm)
      candidates="update search info list install remove doctor --version --help"
      ;;
    vlauncher)
      candidates="--help --search"
      ;;
    vdisplay)
      candidates="--help"
      ;;
    vinstall)
      candidates="requirements system-check media list preflight plan install validate help"
      ;;
    vssh)
      candidates="start stop status connect"
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
  vssh vfetch vhelp vmonitor vdesktop vgraphical
do
  complete -o bashdefault -o default -F _vampire_complete "$_vampire_command"
done
unset _vampire_command
