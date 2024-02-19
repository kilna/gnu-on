# git-on

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

```
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kilna/gnu/HEAD/gnu)" install
```
