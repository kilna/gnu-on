#!/usr/bin/env bash

_gnu_fail() {
  export _gnu_err="${1:-$_gnu_action failed}"
  export _gnu_exit="${2:-1}"
}

export _gnu_err=''
export _gnu_exit=0
export _gnu_action=load
export _gnu_verbose=0
export _gnu_shell=''
while [ $# -gt 0 ]; do
  case "$1" in
    load|unload|on|off|status|env|rcfile|help)
                   _gnu_action="$1";;
    --verbose|-v)  _gnu_verbose=1;;
    --help|-h)     _gnu_action='help';;
    *)             _gnu_action='help'
                   _gnu_fail "Unknown option: $1"
                   break;;
  esac
  shift
done

_gnu_log() {
  [ "$_gnu_verbose" -eq 0 ] && return
  for arg in "$@"; do
    echo "$arg" | sed -e 's/^/gnu: /' >&2
  done
}

_gnu_eval() { return 1; }
export _gnu_source="$0"
if [ -n "$ZSH_VERSION" ]; then
  case "$ZSH_EVAL_CONTEXT" in *:file) _gnu_eval() { return 0; }; ;; esac
  _gnu_source="${(%):-%x}"
  _gnu_shell=zsh
elif [ -n "$BASH_VERSION" ]; then
  if (return 0 2>/dev/null); then  _gnu_eval() { return 0; }; fi
  _gnu_source="${BASH_SOURCE[0]}"
  _gnu_shell=bash
else
  echo "Unsupported shell. Please use bash or zsh" >&2
  sleep 5 # If we're sourced (no way to tell) give the user time to see mesage
  exit 1
fi

_gnu_log "action: $_gnu_action"
_gnu_log "eval: $_gnu_eval"
_gnu_log "source: $_gnu_source"

export _gnu_url="https://githubraw.com/kilna/gnu-on/main/install.sh"
export _gnu_script="$(realpath "$_gnu_source")" # Canonical script location
export _gnu_path="$(echo "$_gnu_script" | sed -e "s;^$HOME/;~/;")" # Pretty
export _gnu_base="$(brew --prefix)/gnu" # Set to /usr/local or /opt by arch

_gnu_log "script: $_gnu_script"
_gnu_log "path: $_gnu_path"
_gnu_log "base: $_gnu_base"

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
  if echo ":$PATH:" | grep -Fq ":$_gnu_base/bin:"; then
    echo "$_gnu_base/bin is in PATH (gnu is on)"
  else
    echo "$_gnu_base/bin is not in PATH (gnu is off)"
  fi
  if echo ":$MANPATH:" | grep -Fq ":$_gnu_base/share/man:"; then
    echo "$_gnu_base/share/man is in MANPATH (gnu man pages are on)"
  else
    echo "$_gnu_base/share/man is not in MANPATH (gnu man pages are off)"
  fi
}

_gnu_warn() {
  echo '# If you are seeing this then you probably meant to eval this like so:'
  echo '# eval "$(gnu '$_gnu_action')"'
}

_gnu_load() {
  # Load the gnu function into the shell, which in turn sources this file
  _gnu_warn
  echo "gnu() { . '$_gnu_script' \"\$@\"; };"
}

_gnu_unload() {
  _gnu_warn
  echo 'typeset -pf gnu >/dev/null 2>&1 && unset -f gnu'
}

# Used to remove or prepend entries from PATH / MANPATH
_gnu_pathspec() {
  local pathvar="$1" # PATH or MANPATH
  local action="$2"  # + to prepend and cleanup, - to cleanup (remove) only
  local exclude="$3" # path to be added / cleaned from the env var
  local add=''; if [ "$action" == '+' ]; then add="$3:"; fi
  echo -n 'export '$pathvar'="'$add'$('
  echo -n   'echo "$'$pathvar'"'     # Gets PATH / MANPATH in : format
  echo -n   "|tr : '\n'"             # Turns : into newlines
  echo -n   "|grep -vxF '$exclude'"  # Removes the path from entries
  echo -n   '|uniq'                  # Removes duplicate entries
  echo -n   '|awk NF'                # Removes blank entries
  echo -n   "|tr '\n' :"             # Turns newlines back to :
  echo -n   "|sed -e 's/:\$//'"      # Removes trailing :
  echo    ')"'
}

_gnu_on() {
  _gnu_load
  _gnu_env
}

_gnu_off() {
  _gnu_warn
  _gnu_pathspec PATH    - $_gnu_base/bin
  _gnu_pathspec MANPATH - $_gnu_base/share/man
  echo 'if [ "$MANPATH" = "" ]; then unset MANPATH; fi'
}

_gnu_env() {
  _gnu_pathspec PATH    + $_gnu_base/bin
  _gnu_pathspec MANPATH + $_gnu_base/share/man
}

_gnu_rcfile() {
  local rcfile="${1:-$HOME/.${_gnu_shell}rc}"
  if grep -Eq 'gnu (on|load|env)' "$rcfile"; then
    echo "The gnu shell extension is already in $rcfile"
    return
  fi
  echo "Adding gnu shell extension loader to $rcfile"
  echo 'eval "$(gnu on)"' >>"$rcfile"
}

case "$_gnu_action" in
  help)     _gnu_help;;
  install)  /bin/bash -c "$(curl -fsSL $_gnu_url)";;
  rcfile)   _gnu_rcfile;;
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
