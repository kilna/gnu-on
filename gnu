#!/usr/bin/env bash

if [[ "$OSTYPE" != darwin* ]]; then
  echo "Meant for MacOS only"
   return 1
fi

_gnu_check() {
  if ! [[ -d /usr/local/gnu/bin || -d /opt/gnu/bin ]]; then
    echo "Gnu utilities are not installed properly, reinstall with:" >&2
    echo >&2
    echo "$ gnu install" >&2
    echo >&2
    echo "or" >&2
    echo >&2
    echo /bin/bash -c "$(curl -fsSL $_gnu_url)" >&2
    export _gnu_exit=2
    return 2
  fi
  if ! (( _gnu_is_sourced )); then
    echo "gnu $_gnu_action must be is_sourced. Run as:" >&2
    echo >&2
    echo "$ source $_gnu_path $_gnu_action" >&2
    echo >&2
    echo "or" >&2
    echo >&2
    echo "$ source $_gnu_path load # Use gnu as a shell extension" >&2
    echo "$ gnu $_gnu_action" >&2
    if [[ "$_gnu_action" == 'on' || "$_gnu_action" == 'off' ]]; then
      echo >&2
      echo "or you can turn gnu $_gnu_action via eval" >&2
      echo >&2
      echo "$ eval \"\$(gnu eval-$_gnu_action)\"" >&2
    fi
    export _gnu_exit=3
    return 3
  fi
}

export _gnu_url="https://raw.githubusercontent.com/kilna/gnu-on/main/install.sh"
export _gnu_source="${BASH_SOURCE[0]:-${(%):-%x}}"
export _gnu_is_sourced=0
if [[ "$_gnu_source" != "$0" ]]; then _gnu_is_sourced=1
elif [[ "$zsh_eval_context" == *'file'* ]]; then  _gnu_is_sourced=1; fi
export _gnu_exit=0
export _gnu_script="$(realpath "$_gnu_source")" # Canonical script location
export _gnu_path="$(echo "$_gnu_script" | sed -e "s;^$HOME/;~/;")" # Pretty
export _gnu_base=/usr/local/gnu;
if /opt/homebrew/bin/brew --prefix >/dev/null 2>&1; then _gnu_base=/opt/gnu; fi

export _gnu_action=load
while [[ $# -gt 0 ]]; do
  case "$1" in
    install|load|''|unload|on|off|eval-on|eval-off) _gnu_action="$1"; shift;;
    help|--help|-h) _gnu_action="help"; shift;;
    *) echo "Unknown option: $1" >&2; _gnu_action="help"; export _gnu_exit=1;;
  esac
done

case "$_gnu_action" in
  help)
    _gnu_found_usage=0
    while read line; do
      (( _gnu_found_usage )) && echo "$line"
      if [[ "$line" == __USAGE__ ]]; then _gnu_found_usage=1; fi
    done < "$_gnu_script"
    unset _gnu_found_usage
  ;;
  install)
    /bin/bash -c "$(curl -fsSL $_gnu_url/install.sh)"
  ;;
  load)
    if _gnu_check; then
      eval "gnu() { source \"$_gnu_script\" \"\$@\"; };"
    fi
  ;;
  unload)
    typeset -f gnu >/dev/null && unset -f gnu
  ;;
  on|load)
    if _gnu_check; then
      export PATH="$_gnu_base/bin:$PATH"
      export MANPATH="$_gnu_base/share/man:$MANPATH"
    fi
  ;;
  off)
    if _gnu_check; then
      # Break-down of how we remove the path from environment
      # echo "$PATH"        # gets the path in : delimited format
      # | tr : '\n'         # Turns : into newlines
      # | grep -vxF (path)  # Removes the path from the newline list
      # | uniq              # Gets rid of duplicate lines/paths
      # | awk NF            # Gets rid of blank lines/paths
      # | tr '\n' :         # Turns it back into a : delimted list
      # | sed -e 's/:$//'   # Removes trailing :
      export PATH="$( echo "$PATH" | tr : '\n' \
                        | grep -vxF $_gnu_base/bin \
                        | uniq | awk NF | tr '\n' : | sed -e 's/:$//' )"
      export MANPATH="$( echo "$MANPATH" | tr : '\n' \
                          | grep -vxF $_gnu_base/share/man \
                          | uniq | awk NF | tr '\n' : | sed -e 's/:$//' )"
    fi
  ;;
  eval-on)
    echo 'export PATH="'$_gnu_base'/bin:$PATH"'
    echo 'export MANPATH="'$_gnu_base'/man:$MANPATH"'
  ;;
  eval-off)
    echo -n 'export PATH="$(echo "$PATH"|tr : '\''\n'\'
    echo -n '|grep -vxF '$_gnu_base'/bin'
    echo    '|uniq|awk NF|tr '\''\n'\'' :|sed -e '\''s/:$//'\'')"'
    echo -n 'export MANPATH="$(echo "$MANPATH"|tr : '\''\n'\'
    echo -n '|grep -vxF '$_gnu_base'/share/man'
    echo    '|uniq|awk NF|tr '\''\n'\'' :|sed -e '\''s/:$//'\'')"'
  ;;
esac

(( _gnu_is_sourced )) || exit _gnu_exit

unset _gnu_url
unset _gnu_source
unset _gnu_is_sourced
unset _gnu_script
unset _gnu_path
unset _gnu_base
unset _gnu_action
unset -f _gnu_check

return $_gnu_exit

__USAGE__

