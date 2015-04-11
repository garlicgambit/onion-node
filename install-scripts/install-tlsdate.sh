#!/bin/bash

# Install tlsdate from source

# Variables
SRCDIR=/usr/local/src/tlsdate;
TLSDATEURL=https://www.github.com/ioerror/tlsdate.git;
LOCKDIR=/tmp/tor-bitcoin.lock/;

# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script";
  exit 0;
fi

# Check if a lockfile/LOCKDIR exists, wait max 30 minutes
TRIES=0
while [[ -d "$LOCKDIR" ]] && [[ "$TRIES" -lt 30 ]]; do
  echo "Temporarily not able to acquire lock on "$LOCKDIR"";
  echo "Other processes might be running...retry in 60 seconds";
  sleep 60;
  TRIES=$(( $TRIES +1 ));
done;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "$LOCKDIR"; then
  trap 'rmdir "$LOCKDIR"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "$LOCKDIR"";
else
  echo "Failed to acquire lock on "$LOCKDIR"";
  echo "The installation script failed...run the install.sh script again to see if you get better results."
  echo "Tip: Reboot the system if the installation keeps failling."
  exit 0;
fi

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
rmdir "$LOCKDIR";
