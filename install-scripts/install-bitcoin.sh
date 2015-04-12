#!/bin/bash

# Install bitcoin from source

# To do:
# - Automatically install latest stable bitcoin version

# Variables
BITCOINVERSION=v0.10.0;
ONIONDIR=/etc/onion-node;
GPGKEYS="$ONIONDIR"/install-scripts/download-gpg-keys.sh;
SRCDIR=/usr/local/src/bitcoin;
BTCURL=https://www.github.com/bitcoin/bitcoin.git;
SWAPCONF=/etc/dphys-swapfile;
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

# Download latest GPG keys
"$ONIONDIR"/

# Download latest version from github.com
echo "Download latest version from "$BTCURL"";

TRIES=0;
while [[ "$TRIES" -lt 10 ]]; do
  if [[ -d "$SRCDIR" ]]; then
    echo ""$SRCDIR" already exits...downloading Bitcoin updates.";
    cd "$SRCDIR";
    git fetch --all --tags && break;
  else
    echo "Downloading full Bitcoin source code.";
    git clone "$BTCURL" "$SRCDIR" && break;
  fi
  sleep 30;
  TRIES=$(( $TRIES +1 ));
  if [[ "$TRIES" -eq 10 ]]; then
    echo "ERROR: The Bitcoin download script has failed.";
    echo "The script will exit now.";
    exit 0;
  fi
done;

echo "Downloaded latest Bitcoin version";

# Verify bitcoin source code
cd "$SRCDIR";
if git tag -v "$BITCOINVERSION" 2>&1 >> /dev/null | grep -q "^gpg: Good signature from" && ! git tag -v "$BITCOINVERSION" 2>&1 >> /dev/null | grep -q "^gpg: Bad signature from"; then
  echo "Good GPG signature...will continue bitcoin installation";
else
  echo "ERROR: Bad or missing GPG signature...exiting bitcoin installation";
  exit 0;
fi

# Temporary increase swap size to 2 GB
echo "Temporary set swap to 2 GB to allow bitcoin to be compiled";
sed -i "s/CONF_SWAPSIZE\=100/CONF_SWAPSIZE\=2000/" "$SWAPCONF";
dphys-swapfile setup;
dphys-swapfile swapon;
echo "Swap set to 2GB";

# Compile and install bitcoin
# Build options:
# - no wallet
# - no gui
# - no upnp

echo "Installing bitcoin version $BITCOINVERSION";
cd "$SRCDIR";
git checkout "$BITCOINVERSION";
./autogen.sh;
./configure --disable-wallet --without-gui --without-miniupnpc;
# 3 threads instead of 4 - 3 is about 1/4 faster then 4 threads
make -j3;
make install;
make clean;
echo "Bitcoin is installed";

# Set swap size to default size
echo "Restore to default swap size...sleeping for 30 seconds to allow system to empty swap";
sleep 30;
sed -i "s/CONF_SWAPSIZE\=2000/CONF_SWAPSIZE\=100/" "$SWAPCONF";
dphys-swapfile setup;
dphys-swapfile swapon;
echo "Swap set to default size";

echo "Bitcoin install script is done";
rmdir "$LOCKDIR";
