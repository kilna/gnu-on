#!/usr/bin/env bash

if [[ "$OSTYPE" != darwin* ]]; then
  echo "Meant for MacOS only"
   return 1
fi

_gnu_check_install() {
  [[ -d /usr/local/gnu/bin ]] && return 0
  [[ -d /opt/gnu/bin ]] && return 0
  echo "Does not look like gnu utilities are installed via homebrew" >&2
  echo "Please run gnu install" >&2
  return 1
}

_gnu_check_is_sourced() {
  (( _gnu_is_sourced )) && return 0
  echo "gnu $_gnu_action must be is_sourced. Run as:" >&2
  echo "$ $_gnu_source_run $_gnu_action" >&2
  echo "or" >&2
  echo "$ $_gnu_source_run load; gnu $_gnu_action" >&2
  if [[ "$_gnu_action" == 'on' || "$_gnu_action" == 'off' ]]; then
    echo "or you can turn gnu $_gnu_action via eval" >&2
    echo "$ eval \"\$($_gnu_run eval-$_gnu_action)\"" >&2
  fi
  return 1
}

_gnu_install() {
  local state="$(set +o)" # Store shell args
  set -e -u -o pipefail
  if ! $(which brew >/dev/null); then # Install brew
    /bin/bash -c "$(curl -fsSL \
      https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  sudo mkdir -p /usr/local/bin
  echo "Copying..."
  sudo cp -v -f "$_gnu_script" /usr/local/bin/
  sudo chmod +x /usr/local/bin/"$_gnu_me"
  local base=/usr/local;
  if /opt/homebrew/bin/brew --prefix >/dev/null 2>&1; then base=/opt; fi
  sudo mkdir -p $base/gnu/bin
  sudo mkdir -p $base/gnu/man/man1
  local packages=(coreutils findutils grep gawk gnu-sed gnu-tar gnu-which)
  local pkg
  for pkg in ${packages[@]}; do
    brew install "$pkg"
    echo "Symlinking..."
    local prefix=$(brew --prefix "$pkg")
    cd "$prefix/libexec/gnubin/"
    local file
    for file in *; do
      sudo ln -v -f -s -L "$(pwd)/$file" "$base/gnu/bin/$file"
    done
    cd "$prefix/libexec/gnuman/man1/"
    for file in *; do
      sudo ln -v -f -s -L "$(pwd)/$file" "$base/gnu/man/man1/$file"
    done
  done
  eval "$state" # Reset shell args
}

export _gnu_source="${BASH_SOURCE[0]:-${(%):-%x}}"
export _gnu_script="$(realpath "$_gnu_source")"
export _gnu_me="$(basename "$_gnu_script")"
export _gnu_dir="$(dirname $_gnu_script | sed -e "s;^$HOME/;~/;")"
export _gnu_path="$_gnu_dir/$_gnu_me"
export _gnu_is_sourced=0; [[ "$_gnu_source" != "$0" ]] && _gnu_is_sourced=1
[[ "$zsh_eval_context" == *'file'* ]] && _gnu_is_sourced=1
export _gnu_run="$_gnu_path"
export _gnu_source_run="source $_gnu_path"
export _gnu_where="$(whereis -q -b "$_gnu_me")"
if [[ "$_gnu_where" && "$(realpath "$_gnu_where")" ==  "$_gnu_script" ]]; then
  _gnu_run="$_gnu_me"
  _gnu_source_run='source "$(whereis -q -b $_gnu_me)"'
fi
export _gnu_action=load

while [[ $# -gt 0 ]]; do case "$1" in
  install|load|unload|on|off|eval-on|eval-off) _gnu_action="$1"; shift;;
  *) echo "Unknown option: $1" >&2; (( _gnu_is_sourced )) && return 1 || exit 1;;
esac; done

case "$_gnu_action" in
  install)
    _gnu_install
  ;;
  load)
    _gnu_check_install
    _gnu_check_is_sourced
    eval "gnu() { source \"$_gnu_script\" \"\$@\"; };"
  ;;
  unload)
    typeset -f gnu >/dev/null && unset -f gnu
  ;;
  on)
    _gnu_check_install
    _gnu_check_is_sourced
    export PATH="/usr/local/gnu/bin:$PATH"
    export MANPATH="/usr/local/gnu/man:$MANPATH"
  ;;
  off)
    _gnu_check_install
    _gnu_check_is_sourced
    export PATH="$(echo "$PATH"|tr : '\n'|grep -v -x -F /usr/local/gnu/bin|uniq|awk NF|tr '\n' :|sed -e 's/:$//')"
    export MANPATH="$(echo "$MANPATH"|tr : '\n'|grep -v -x -F /usr/local/gnu/man|uniq|awk NF|tr '\n' :|sed -e 's/:$//')"
  ;;
  eval-on)
    echo 'export PATH="/usr/local/gnu/bin:$PATH"'
    echo 'export MANPATH="/usr/local/gnu/man:$MANPATH"'
  ;;
  eval-off)
    echo 'export PATH="$(echo "$PATH"|tr : '\''\n'\''|grep -v -x -F /usr/local/gnu/bin|uniq|awk NF|tr '\''\n'\'' :|sed -e '\''s/:$//'\'')"'
    echo 'export MANPATH="$(echo "$MANPATH"|tr : '\''\n'\''|grep -v -x -F /usr/local/gnu/man|uniq|awk NF|tr '\''\n'\'' :|sed -e '\''s/:$//'\'')"'
  ;;
esac
unset _gnu_source
unset _gnu_script
unset _gnu_me
unset _gnu_dir
unset _gnu_path
unset _gnu_run
unset _gnu_source_run
unset _gnu_action
unset _gnu_quiet
unset _gnu_is_sourced
unset _gnu_where
unset -f _gnu_install
unset -f _gnu_check_install
unset -f _gnu_check_is_sourced

