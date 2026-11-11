# Vampire OS interactive shell defaults.
export EDITOR=${EDITOR:-vi}
export PAGER=${PAGER:-less}
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ -n "${PS1:-}" ]; then
  PS1='\[\033[1;31m\]vampire\[\033[0m\] \w # '
fi
