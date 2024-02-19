# gnu-on

Run GNU tools by default on Mac in an easily switchable way

## Overview

If you want to run default GNU (linux-like) command line utilities in your
shell, then this tool makes it easy. How brew installs them, they are placed in
the path named with a g prefix, gls, gsed, gwhich, etc.; this tool installs them
in your path in a single location at /usr/local/gnu/bin (or /opt/gnu/bin for
MacOS M1 machines, per convention). It also makes it possible to to turn your
shell session back into a default MacOS environment on the fly.

## Tools Installed

MacOS tools:
* brew

GNU tools:
* coreutils (many CLI utils)
* bash
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
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kilna/gnu-on/main/install.sh)"
```

## Usage

Load into shell as an extension (don't need to source after)

```
$ source /usr/local/bin/gnu
$ gnu on                             # Turns on gnu utils in path
$ gnu off                            # Turns off gnu utils in path
```

Turn on via eval

```
$ eval "$(gnu eval-on)"
```

Or alternately source without loading as extension:

```
$ . /usr/local/bin/gnu on
```

Disabling of gnu tools (and restore to MacOS default tools) is done with
either `gnu off` or `gnu eval-off` using the same syntax as "on":

```
$ eval "$(gnu eval-off)"
```

Or:

```
$ . /usr/local/bin/gnu off
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

