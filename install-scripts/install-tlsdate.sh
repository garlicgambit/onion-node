#!/bin/bash

# Install tlsdate from source

# Variables
SRCDIR=/usr/local/src/tlsdate;
TLSDATEURL=https://www.github.com/ioerror/tlsdate.git;


# Download latest version from github.com
echo "Download latest version from "$TLSDATEURL"";

if [[ -d "$SRCDIR" ]]; then
  echo "$SRCDIR already exists...downloading updates";
  cd "$SRCDIR";
  git pull --all;
else
  echo "Download full tlsdate source code";
  git clone "$TLSDATEURL" "$SRCDIR";
fi

echo "Downloaded latest version";

# Install tlsdate
echo "Installing tlsdate";
cd "$SRCDIR";
./autogen.sh;
./configure;
make -j3;
make install;
make clean;
echo "tlsdate is installed";

echo "tlsdate install script is done";
