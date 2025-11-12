#!/bin/sh

set -e -u

gh_url=https://githubraw.com

if ! $(which brew >/dev/null); then # Install brew
  echo "Installing brew"
  /bin/bash -c "$(curl -fsSL $gh_url/Homebrew/install/HEAD/install.sh)"
fi

echo "Copying gnu-on script..."
[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin
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

sudo mv -v -f "$TMPDIR/gnu-on/gnu" /usr/local/bin/
sudo chmod 755 /usr/local/bin/gnu

rm -rf "$TMPDIR/gnu-on/"

base="$(brew --prefix | sed -e 's|/homebrew$||')"

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

cat <<'EOF'


To enable in your shell as a shell extension, run:

$ gnu rcfile

Then you will be able to use 'gnu on' and 'gnu off' the next time you fire up
a new shell.

EOF
