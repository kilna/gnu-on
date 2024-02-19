#!/usr/bin/env bash

set -e -u -o pipefail

gh_url=https://raw.githubusercontent.com

if ! $(which brew >/dev/null); then # Install brew
  echo "Installing brew"
  /bin/bash -c "$(curl -fsSL $gh_url/Homebrew/install/HEAD/install.sh)"
fi

echo "Copying gnu-on script..."
curl -o "$TMPDIR/gnu" -fsSL $gh_url/kilna/gnu-on/main/gnu
sudo mkdir -p /usr/local/bin
sudo mv -v -f "$TMPDIR/gnu" /usr/local/bin/
sudo chmod +x /usr/local/bin/gnu
curl -o "$TMPDIR/README.md" -fsSL $gh_url/kilna/gnu-on/main/README.md
cat "$TMPDIR/README.md" >>/usr/local/bin/gnu
rm -f "$TMPDIR/README.md"

base=/usr/local;
if /opt/homebrew/bin/brew --prefix >/dev/null 2>&1; then
  base=/opt
fi

sudo mkdir -p $base/gnu/bin
sudo mkdir -p $base/gnu/share/man/man1

packages=(coreutils findutils grep gawk gnu-sed gnu-tar gnu-which)

for pkg in ${packages[@]}; do

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

