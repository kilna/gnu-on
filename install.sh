#!/bin/sh

set -e -u

# 1. Must NOT be root
if [ "$EUID" -eq 0 ]; then
  echo "This script should not be run as root." >&2
  exit 1
fi

# 2. Must have sudo privileges (without prompting)
if sudo -n true 2>/dev/null; then
  echo "User $USER can sudo without a password prompt (cached or NOPASSWD)."
else
  # If no cached credentials, check if the user is in the sudoers list at all
  if sudo -l >/dev/null 2>&1; then
    echo "User $USER has sudo privileges but may need to enter a password."
  else
    echo "User $USER cannot sudo." >&2
    exit 1
  fi
fi

sudo -E bash <<'EOF'

gh_url=https://githubraw.com
export as_user="sudo -u $SUDO_USER"

if ! $(which brew >/dev/null); then # Install brew
  echo "Installing brew"
  /bin/bash -c "$(curl -fsSL $gh_url/Homebrew/install/HEAD/install.sh)"
fi

echo "Copying gnu-on script..."
[ -d /usr/local/bin ] || mkdir -p /usr/local/bin
mkdir -p "$TMPDIR/gnu-on"
if [ -e "$(dirname $0)/gnu" ] && [ -e "$(dirname $0)/README.md" ]; then
  cp -v -f "$(dirname $0)/gnu" "$TMPDIR/gnu-on"
  cp -v -f "$(dirname $0)/README.md" "$TMPDIR/gnu-on"
else
  curl -o "$TMPDIR/gnu-on/gnu" -fsSL $gh_url/kilna/gnu-on/main/gnu
  curl -o "$TMPDIR/gnu-on/README.md" -fsSL $gh_url/kilna/gnu-on/main/README.md
fi

# Append USAGE from the README.md so I don't have to update in two places
output=0
while IFS='' read line; do
  case "$line" in USAGE:*) output=1;; esac
  [ "$output" -eq 0 ] && continue
  [ "$line" == '```' ] && break
  echo "$line" >>"$TMPDIR/gnu-on/gnu"
done <"$TMPDIR/gnu-on/README.md"

mv -v -f "$TMPDIR/gnu-on/gnu" /usr/local/bin/
chmod 755 /usr/local/bin/gnu

rm -rf "$TMPDIR/gnu-on/"

base="$($as_user brew --prefix | sed -e 's|/homebrew$||')"

mkdir -p $base/gnu/bin
mkdir -p $base/gnu/share/man/man1

packages="coreutils findutils grep gawk gnu-sed gnu-tar gnu-which"

for pkg in $packages; do

  $as_user brew install "$pkg"

  echo "Symlinking..."
  prefix=$($as_user brew --prefix "$pkg")

  cd "$prefix/libexec/gnubin/"
  for file in *; do
    ln -v -f -s -L "$(pwd)/$file" "$base/gnu/bin/$file"
  done

  cd "$prefix/libexec/gnuman/man1/"
  for file in *; do
    ln -v -f -s -L "$(pwd)/$file" "$base/gnu/share/man/man1/$file"
  done

done

EOF

cat <<'EOF'


To enable in your shell as a shell extension, run:

$ gnu rcfile

Then you will be able to use 'gnu on' and 'gnu off' the next time you fire up
a new shell.

EOF
