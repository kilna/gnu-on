#!/bin/sh

set -e -u

gh_url=https://githubraw.com

if ! $(which brew >/dev/null); then # Install brew
  echo "Installing brew"
  curl -fL $gh_url/Homebrew/install/HEAD/install.sh | bash
fi

# Where the 'gnu' script is installed
GNU_DIR="${GNU_DIR:-/usr/local/bin}"

# Where brew gnu utils are linked from
GNU_BASE="${GNU_BASE:-$(brew --prefix)/opt}"

echo "Copying gnu-on script..."
[ -d "$GNU_DIR" ] || sudo mkdir -p "$GNU_DIR"
TMPDIR="$(mktemp -d)"
if [ -e "$(dirname $0)/gnu" ] && [ -e "$(dirname $0)/README.md" ]; then
  cp -v -f "$(dirname $0)/gnu"       "$TMPDIR"
  cp -v -f "$(dirname $0)/README.md" "$TMPDIR"
else
  curl -o "$TMPDIR/gnu"       -fL $gh_url/kilna/gnu-on/main/gnu
  curl -o "$TMPDIR/README.md" -fL $gh_url/kilna/gnu-on/main/README.md
fi

# Append USAGE from the README.md so I don't have to update in two places
output=0
while IFS='' read line; do
  case "$line" in USAGE:*) output=1;; esac
  [ "$output" -eq 0 ] && continue
  [ "$line" == '```' ] && break
  echo "$line" >>"$TMPDIR/gnu"
done <"$TMPDIR/README.md"

sudo mv -v -f "$TMPDIR/gnu" "$GNU_DIR"
sudo chmod 755 "$GNU_DIR/gnu"

rm -rf "$TMPDIR"

sudo mkdir -p "$GNU_BASE/bin"
sudo mkdir -p "$GNU_BASE/share/man/man1"

packages="coreutils findutils grep gawk gnu-sed gnu-tar gnu-which"

# ToDO look up remaining packages to install
# query to install
# install
# query to install in profile
# install in profile

# export PS3='Promt goes here>'
# select item in foo bar baz
# do
#   case "$item" in
#     foo) : ;;
#     bar) : ;;
#     baz) : ;;
#   esac
#   break
# done

