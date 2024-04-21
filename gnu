#!/usr/bin/env bash

_gnu_fail() {
  export _gnu_err="${1:-$_gnu_action failed}"
  export _gnu_exit="${2:-1}"
}

export _gnu_script='/usr/local/bin/gnu'
export _gnu_brew_opt="$(brew --prefix)/opt"
export _gnu_url="https://githubraw.com/kilna/gnu-on/main/install.sh"
_gnu_log "script: $_gnu_script"
_gnu_log "url: $_gnu_url"

export _gnu_err=''
export _gnu_exit=0
export _gnu_action=load
export _gnu_verbose=0
export _gnu_shell=''
_gnu_eval() { return 0; }
while [ $# -gt 0 ]; do
  case "$1" in
    load|unload|on|off|status|install|help)
                   _gnu_action="$1";;
    --eval|-e)     _gnu_eval() { return 1; };;
    --verbose|-v)  _gnu_verbose=1;;
    --help|-h)     _gnu_action='help';;
    *)             _gnu_action='help'
                   _gnu_fail "Unknown option: $1"
                   break;;
  esac
  shift
done
_gnu_log "action: $_gnu_action"

_gnu_log() {
  [ "$_gnu_verbose" -eq 0 ] && return
  for arg in "$@"; do
    echo "$arg" | sed -e 's/^/gnu: /' >&2
  done
}

_gnu_help() {
  found=0
  while IFS='' read line; do
    [ "$found" -eq 1 ] && echo "$line"
    [ "$line" = '__USAGE__' ] && found=1
  done < "$_gnu_script"
  unset found
}

_gnu_status() {
  if typeset -pf gnu >/dev/null 2>&1; then
    echo "$_gnu_script shell extension function is loaded"
  else
    echo "$_gnu_script shell extension function is not loaded"
  fi
}

_gnu_warn() {
cat <<EOF
# If you are seeing this then you probably meant to run gnu load in an eval to
# load gnu as a shell extension, e.g.:

#   eval "$(gnu load)"

# Once loaded with eval the first time, then you can use 'gnu' commands
# without eval:

#   gnu $_gnu_action

EOF
}

_gnu_load() {
  # Load the gnu function into the shell, which in turn sources this file
  _gnu_warn
  echo "gnu() { . '$_gnu_script' -e \"\$@\"; };"
}

_gnu_unload() {
  _gnu_warn
  echo 'typeset -pf gnu >/dev/null 2>&1 && unset -f gnu'
}

_gnu_on() {
  echo 'gnu_on(){ local gnubin; local gnuman'
  echo 'local prefix="$( /opt/homebrew/bin/brew --prefix 2>/dev/null || brew --prefix )"'
  echo 'for gnubin in "$prefix"/opt/*/libexec/gnubin; do'
  echo '  gnuman="$(echo "$gnubin"|sed -e "s|/libexec/gnubin\$|/share/man|")"'
  echo '  gnu_on_addpath PATH "$gnubin"; gnu_on_addpath MANPATH "$gnuman"'
  echo 'done; }'
  echo -n 'gnu_on_addpath(){'        # $1 is PATH or MANPATH, $2 is path to add
  echo -n   'export $1="$2:$('       # export PATH="/path/to/add:$(
  echo -n     'eval "echo \"\$$1\""' # get contents of PATH var as : delimited
  echo -n     "|tr : '\n'"           # translate : to newline delimited
  echo -n     '|grep -vxF "$2"'      # remove /path/to/add to prevent dupes
  echo -n     '|uniq'                # remove any other dupe entries
  echo -n     '|awk NF'              # remove blank entries
  echo -n     "|tr '\n' :"           # translate newline delimited back to :
  echo -n     "|sed -e 's/:\$/"      # remove trailing : left by above
  echo -n   ')";'                    # end subshell, string from 2nd line
  echo    '}'                        # end function definition
  echo 'gnu_on; unset -f gnu_on gnu_on_addpath'
}

_gnu_off() {
  _gnu_warn
  echo 'gnu_off(){ local gnubin; local gnuman'
  echo 'local prefix="$( /opt/homebrew/bin/brew --prefix 2>/dev/null || brew --prefix )"'
  echo 'for gnubin in "$prefix"/opt/*/libexec/gnubin; do'
  echo '  gnuman="$(echo "$gnubin"|sed -e "s|/libexec/gnubin\$|/share/man|")"'
  echo '  gnu_off_rmpath PATH "$gnubin"; gnu_off_rmpath MANPATH "$gnuman"'
  echo 'done; if [ "$MANPATH" = "" ]; then unset MANPATH; fi; }'
  echo -n 'gnu_off_rmpath(){'        # $1 is PATH or MANPATH, $2 is path to nix
  echo -n   'export $1="$('          # export PATH="$(
  echo -n     'eval "echo \"\$$1\""' # get contents of PATH var as : delimited
  echo -n     "|tr : '\n'"           # translate : to newline delimited
  echo -n     '|grep -vxF "$2"'      # remove /path/to/remove
  echo -n     '|uniq'                # remove any dupe entries
  echo -n     '|awk NF'              # remove blank entries
  echo -n     "|tr '\n' :"           # translate newline delimited back to :
  echo -n     "|sed -e 's/:\$/"      # remove trailing : left by above
  echo -n   ')";'                    # end subshell, string from 2nd line
  echo    '}'                        # end function definition
  echo 'gnu_off; unset -f gnu_off gnu_off_rmpath'
}

case "$_gnu_action" in
  help)     _gnu_help;;
  install)  curl -fL $_gnu_url | sh;;
  load)     _gnu_load;;
  unload)   if _gnu_eval; then eval "$(_gnu_unload)" || _gnu_fail
                          else _gnu_unload; fi;;
  on)       if _gnu_eval; then eval "$(_gnu_on)"     || _gnu_fail
                          else _gnu_on; fi;;
  off)      if _gnu_eval; then eval "$(_gnu_off)"    || _gnu_fail
                          else _gnu_off; fi;;
  status)   _gnu_status;;
esac

if _gnu_eval; then
  _gnu_log "$(echo "$PATH" | tr : '\n' | sed 's/^/PATH: /')"
  _gnu_log "$(typeset -pf gnu 2>/dev/null || echo 'no gnu function')"
  _gnu_log "$(_gnu_status)"
fi

[ -n "$_gnu_err" ] && echo "gnu error: $_gnu_err" >&2

_gnu_eval || exit $_gnu_exit

[ "$_gnu_exit" -gt 0 ] && gnu_exit=$_gnu_exit

# Clean up all _gnu functions
funcs=($(typeset -pf | grep -e '^_gnu.* ()' | sed -e 's/ ().*//'))
for func in "${funcs[@]}"; do unset -f $func; done
unset func funcs

# Clean up all _gnu vars
vars=($( typeset -px|cut -f2- -d' '|sed -e 's/-x //; s/=.*//'|grep -e ^_gnu ))
for var in "${vars[@]}"; do unset $var; done
unset var vars

return ${gnu_exit:-0}

# Usage is appended below by install.sh from contents of Usage section
# of README.md
__USAGE__
