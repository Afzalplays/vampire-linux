# Keep the mobile bring-up console discoverable after login.
if [ -t 0 ] && [ -t 1 ]; then
  export PS1='[vampire-mobile]# '
  alias mobile='vmobile'
fi
