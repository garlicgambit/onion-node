#!/bin/bash

set -eu

# Check if Tor and bitcoind process are running, if not start them.

# Variables
BITCOINUSER=bitcoinuser;
LOCKDIR=/tmp/tor-bitcoin.lock/;


# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script";
  exit 0;
fi

# Check if Tor process is running - start Tor if it's not running
# Only proceed if no lockfile is set
if [[ "$(pgrep "tor" -u debian-tor >> /dev/null && echo "Running")" != "Running" ]]; then
  if mkdir "$LOCKDIR"; then
    trap 'rmdir "$LOCKDIR"; exit' INT TERM EXIT;
    echo "Successfully acquired lock on "$LOCKDIR"";
    echo "Tor is not running...starting Tor";
    /etc/init.d/tor start;
    sleep 30;
    rmdir "$LOCKDIR";
  else
    echo "Failed to acquire lock on "$LOCKDIR"";
    exit 0;
  fi
fi

# Check if bitcoind process is running - start bitcoind if it's not running
# Only proceed if no lockfile is set
if [[ "$(pgrep "bitcoind" >> /dev/null && echo "Running")" != "Running" ]]; then
  if mkdir "$LOCKDIR"; then
    trap 'rmdir "$LOCKDIR"; exit' INT TERM EXIT;
    echo "Successfully acquired lock on "$LOCKDIR"";
    echo "bitcoind is not running...starting bitcoind";
    sudo -u "$BITCOINUSER" bitcoind -daemon >> /dev/null;
    rmdir "$LOCKDIR";
  else
    echo "Failed to acquire lock on "$LOCKDIR"";
    exit 0;
  fi
fi
