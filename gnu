#!/usr/bin/env bash

_gnu_fail() {
  export _gnu_err="${1:-$_gnu_action failed}"
  export _gnu_exit="${2:-1}"
}

export _gnu_err=''
export _gnu_exit=0
export _gnu_action=load
export _gnu_verbose=0
while [ $# -gt 0 ]; do
  case "$1" in
    load|unload|on|off|status|env|help) _gnu_action="$1";;
    --verbose|-v)                       _gnu_verbose=1;;
    --help|-h)                          _gnu_action='help';;
    *)                                  _gnu_action='help'
                                        _gnu_fail "Unknown option: $1"
                                        break;;
  esac
  shift
done

_gnu_log() {
  (( _gnu_verbose )) || return
  for arg in "$@"; do
    echo "$arg" | sed -e 's/^/gnu: /' >&2
  done
}

export _gnu_eval=0
export _gnu_source="$0"
if [ -n "$ZSH_VERSION" ]; then 
  case $ZSH_EVAL_CONTEXT in *:file) _gnu_eval=1;; esac
  _gnu_source="${(%):-%x}"
elif [ -n "$KSH_VERSION" ]; then
  arg0_canonical="$(cd -- "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")"
  script_canonical="$(
    cd -- "$(dirname -- "${.sh.file}")" && pwd -P)/$(basename -- "${.sh.file}"
  )"
  [ "$arg0_canonical" != "$script_canonical" ] && _gnu_eval=1
  unset arg0_canonical script_canonical
  _gnu_source="${.sh.file}"
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && _gnu_eval=1
  _gnu_source="${BASH_SOURCE[0]}"
else
  if [ "${0##*/}" == 'gnu' ]; then
    _gnu_eval=1
  else
    # We're in a shell that doesn't tell us the source file, and it looks like
    # $0 isn't a reference to the gnu script... find it in the path instead
    _gnu_source="$(whereis -b -q gnu 2>/dev/null || which gnu 2>/dev/null)"
    if [ -z "$_gnu_source" ]; then
      echo "Cannot determine 'gnu' location in this shell" >&2
      exit 1
    fi
  fi
fi

_gnu_log "action: $_gnu_action"
_gnu_log "eval: $_gnu_eval"
_gnu_log "source: $_gnu_source"

_gnu_eval() { (( $_gnu_eval )) || return 1; };

export _gnu_url="https://raw.githubusercontent.com/kilna/gnu-on/main/install.sh"
export _gnu_script="$(realpath "$_gnu_source")" # Canonical script location
export _gnu_path="$(echo "$_gnu_script" | sed -e "s;^$HOME/;~/;")" # Pretty
export _gnu_base=/usr/local/gnu;
/opt/homebrew/bin/brew --prefix >/dev/null 2>&1 && _gnu_base=/opt/gnu

_gnu_log "script: $_gnu_script"
_gnu_log "path: $_gnu_path"
_gnu_log "base: $_gnu_base"

_gnu_help() {
  local found=0
  while read line; do
    (( found )) && echo "$line"
    if [ "$line" == __USAGE__ ]; then found=1; fi
  done < "$_gnu_script"
}

_gnu_status() {
  if typeset -pf gnu >/dev/null 2>&1; then
    echo "gnu shell extension function is loaded"
  else
    echo "gnu shell extension function is not loaded"
  fi
  if echo ":$PATH:" | grep -Fq ":$_gnu_base/bin:"; then
    echo "$_gnu_base/bin is in path (gnu is on)"
  else
    echo "$_gnu_base/bin is not in path (gnu is off)"
  fi
}

_gnu_warn() {
  echo '# If you are seeing this then you probably meant to eval this like so:'
  echo '# eval "$(gnu '$_gnu_action')"'
}

_gnu_load() {
  # Load the gnu function into the shell, which in turn sources this file
  _gnu_warn
  echo "gnu() { source '$_gnu_script' \"\$@\"; };"
}

_gnu_unload() {
  _gnu_warn
  echo 'typeset -pf gnu >/dev/null 2>&1 && unset -f gnu'
}

_gnu_on() {
  _gnu_load
  _gnu_env
}

_gnu_off() {
  _gnu_warn
  echo -n 'export PATH="$('
  echo -n   'echo "$PATH"'                # Gets PATH in : delimited format
  echo -n   "|tr : '\n'"                  # Turns : into newlines
  echo -n   "|grep -vxF '$_gnu_base/bin'" # Removes the path from entries
  echo -n   '|uniq'                       # Removes duplicate entries
  echo -n   '|awk NF'                     # Removes blank entries
  echo -n   "|tr '\n' :"                  # Turns newlines back to :
  echo -n   "|sed -e 's/:\$//'"           # Removes trailing :
  echo    ')"'
  echo -n 'export MANPATH="$('
  echo -n   'echo "$MANPATH"'                   # Gets MANPATH in : format
  echo -n   "|tr : '\n'"                        # Turns : into newlines
  echo -n   "|grep -vxF '$_gnu_base/share/man'" # Removes the path from entries
  echo -n   '|uniq'                             # Removes duplicate entries
  echo -n   '|awk NF'                           # Removes blank entries
  echo -n   "|tr '\n' :"                        # Turns newlines back to :
  echo -n   "|sed -e 's/:\$//'"                 # Removes trailing :
  echo    ')"'
  echo 'if [ "$MANPATH" == "" ]; then unset MANPATH; fi'
}

_gnu_env() {
  echo "export PATH=\"$_gnu_base/bin:\$PATH\""
  echo "export MANPATH=\"$_gnu_base/share/man:\$MANPATH\""
}

case "$_gnu_action" in
  help)     _gnu_help;;
  install)  /bin/bash -c "$(curl -fsSL $_gnu_url)";;
  load)     if _gnu_eval; then eval "$(_gnu_load)"   || _gnu_fail
                          else _gnu_load; fi;;
  unload)   if _gnu_eval; then eval "$(_gnu_unload)" || _gnu_fail
                          else _gnu_unload; fi;;
  on)       if _gnu_eval; then eval "$(_gnu_on)"     || _gnu_fail
                          else _gnu_on; fi;;
  off)      if _gnu_eval; then eval "$(_gnu_off)"    || _gnu_fail
                          else _gnu_off; fi;;
  status)   _gnu_status;;
  env)      _gnu_env;;
esac

if _gnu_eval; then
  _gnu_log "$(echo "$PATH" | tr : '\n' | sed 's/^/PATH: /')"
  _gnu_log "$(typeset -pf gnu 2>/dev/null|| echo 'no gnu func')"
  _gnu_log "$(_gnu_status)"
fi

[ -n "$_gnu_err" ] && echo "gnu error: $_gnu_err" >&2

_gnu_eval || exit $_gnu_exit

[ "$_gnu_exit" -gt 0 ] && gnu_exit=$_gnu_exit

# Clean up all _gnu functions
funcs="$(typeset -pf|grep -e '^_gnu.* ()'|sed -e 's/ ().*//')"
for func in $funcs; do unset -f $func; done; unset funcs func

# Clean up all _gnu vars
vars="$(typeset -px|cut -f2- -d' '|sed -e 's/-x //;s/=.*//'|grep -e ^_gnu|cat)"
for var in $vars; do unset $var; done; unset vars var

return ${gnu_exit:-0}

__USAGE__
