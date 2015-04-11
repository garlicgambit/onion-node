#!/bin/bash

# Install bitcoin from source

# To do:
# - Automatically install latest stable bitcoin version

# Variables
BITCOINVERSION=v0.10.0;
SRCDIR=/usr/local/src/bitcoin;
BTCURL=https://www.github.com/bitcoin/bitcoin.git;
SWAPCONF=/etc/dphys-swapfile;

# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script";
  exit 0;
fi

# Download latest version from github.com
echo "Download latest version from "$BTCURL"";

if [[ -d "$SRCDIR" ]]; then
  echo "$SRCDIR already exists...downloading updates";
  cd "$SRCDIR";
  git pull --all;
else
  echo "Download full bitcoin source code";
  git clone "$BTCURL" "$SRCDIR";
fi

echo "Downloaded latest version";

# Verify bitcoin source code
cd "$SRCDIR";
if git tag -v "$BITCOINVERSION" 2>&1 >> /dev/null | grep -q "gpg: Good signature from" && ! git tag -v "$BITCOINVERSION" 2>&1 >> /dev/null | grep -q "gpg: Bad signature from"; then
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
