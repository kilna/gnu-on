# gnu-on

Run GNU tools by default on Mac in an easily switchable way

## Features

* Makes it easy to run the most common GNU (linux-like) versions of command line
  tools on the Mac by default *without* having to use Homebrew's g-prefixes
  (for example `gsed` to run GNU's `sed`... you can have the same `sed` as
  linux)
* Loads all tools into one directory for easy enabling/disabling in `$PATH`
* Provides a shell extension to make switching between GNU and default MacOS
  CLI tools
* Also sets up symlinks so the `man` command for help works as well
* Compatibility with both `bash` and `zsh`
* Compatibility with new M-series MacOS machines

## Tools Installed

MacOS tools:
* brew

GNU tools:
* coreutils (many CLI utils)
* findutils (find, locate, updatedb, xargs)
* grep (egrep, fgrep)
* awk
* sed
* tar
* which

## Install

This will install all of the above, and make symlinks into `/usr/local/gnu`
or `/opt/gnu` for all gnu tools, so you have one path to add.

```
curl -fL https://githubraw.com/kilna/gnu-on/main/install.sh | sudo sh
```

To install without root (administrator) privileges:

```
curl -fL https://githubraw.com/kilna/gnu-on/main/install.sh | sh
```

## Usage

```
USAGE: gnu [command] [options]

Options:

  --verbose : Show debugging information
         -v

Commands:

  * load    : Enable shell extension
              (Running 'gnu' after does not require sourcing or eval)

  * unload  : Disable shell extension

  * on      : Loads the shell extension, and includes the GNU CLI tool in your
              $PATH, overriding default MacOS CLI utils

  * off     : Remove GNU from your $PATH, re-enabling MacOS CLI utils

    status  : Show the status of gnu shell extension and path

    env     : Display shell text that can enable GNU CLI utils, without
              extension

    bashrc : Adds 'eval "$(gnu on)"' to ~/.bashrc if it isn't there
    zshrc   : ^ Same for ~/.zshrc

    help    : Show usage

* = Command will display shell code to run if not sourced or within an eval.
    If sourced, the commands will be run directly in the current shell.

For usage examples see https://github.com/kilna/gnu-on
```

## Examples

First, enable in your shell after install, if you haven't already:

```
$ gnu rcfile
```

Fire up a new shell session (or run `eval "$(gnu on)"` yourself) and check:

```
$ gnu status
/usr/local/bin/gnu shell extension function is loaded
/usr/local/gnu/bin is not in PATH (gnu is off)
/usr/local/gnu/share/man is not in MANPATH (gnu man pages are off)
$ sort --version
sort (GNU coreutils) 9.4
...
```

To disable GNU utils and return to standard MacOS CLI commands:

```
$ gnu off
/usr/local/bin/gnu shell extension function is loaded
/usr/local/gnu/bin is not in PATH (gnu is off)
/usr/local/gnu/share/man is not in MANPATH (gnu man pages are off)
$ gnu status
$ sort --version
2.3-Apple (165.80.1)
```

## Manual enabling

You can optionally run the install and never use `gnu` itself; you can
enable gnu tools in your shell by adding the following to your path on an
Intel-based Mac:

```
export PATH="/usr/local/gnu/bin:$PATH"
export MANPATH="/usr/local/gnu/share/man:$MANPATH"
```

Or for M-series processor Macs:

```
export PATH="/opt/gnu/bin:$PATH"
export MANPATH="/opt/gnu/share/man:$MANPATH"
```

## Author

Kilna, Anthony <kilna@kilna.com>

