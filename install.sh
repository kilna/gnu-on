#!/bin/sh

set -e -u

gh_url=https://githubraw.com

if ! $(which brew >/dev/null); then # Install brew
  echo "Installing brew"
  /bin/bash -c "$(curl -fsSL $gh_url/Homebrew/install/HEAD/install.sh)"
fi

echo "Copying gnu-on script..."
mkdir -p "$TMPDIR/gnu-on"
curl -o "$TMPDIR/gnu-on/gnu" -fsSL $gh_url/kilna/gnu-on/main/gnu
sudo mkdir -p /usr/local/bin
sudo mv -v -f "$TMPDIR/gnu-on/gnu" /usr/local/bin/
sudo chmod 755 /usr/local/bin/gnu
sudo chown root:root /usr/local/bin/gnu

# Append USAGE from the README.md so I don't have to update in two places
curl -o "$TMPDIR/gnu-on/README.md" -fsSL $gh_url/kilna/gnu-on/main/README.md
output=0
while IFS='' read line; do
  case "$line" in USAGE:*) output=1;; esac
  [ "$output" -eq 0 ] && continue
  [ "$line" == '```' ] && break
  echo "$line" >>/usr/local/bin/gnu
done <"$TMPDIR/gnu-on/README.md"
rm -rf "$TMPDIR/gnu-on/"

base=/usr/local;
if /opt/homebrew/bin/brew --prefix >/dev/null 2>&1; then
  base=/opt
fi

sudo mkdir -p $base/gnu/bin
sudo mkdir -p $base/gnu/share/man/man1

packages="coreutils findutils grep gawk gnu-sed gnu-tar gnu-which"

for pkg in $packages; do

  brew install "$pkg"

  echo "Symlinking..."
  prefix=$(brew --prefix "$pkg")

  cd "$prefix/libexec/gnubin/"
  for file in *; do
    sudo ln -v -f -s -L "$(pwd)/$file" "$base/gnu/bin/$file"
  done

  cd "$prefix/libexec/gnuman/man1/"
  for file in *; do
    sudo ln -v -f -s -L "$(pwd)/$file" "$base/gnu/share/man/man1/$file"
  done

done

