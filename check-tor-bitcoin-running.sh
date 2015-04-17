#!/bin/bash

set -eu

# Check if Tor and bitcoind process are running, if not start them.

# Variables
readonly BITCOIN_USER=bitcoinuser;
readonly LOCK_DIR=/tmp/tor-bitcoin.lock/;


# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script";
  exit 0;
fi

# Check if Tor process is running - start Tor if it's not running
# Only proceed if no lockfile is set
if [[ "$(pgrep "tor" -u debian-tor >> /dev/null && echo "Running")" != "Running" ]]; then
  if mkdir "${LOCK_DIR}"; then
    trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT;
    echo "Successfully acquired lock on "${LOCK_DIR}"";
    echo "Tor is not running...starting Tor";
    /etc/init.d/tor start;
    sleep 30;
    rmdir "${LOCK_DIR}";
  else
    echo "Failed to acquire lock on "${LOCK_DIR}"";
    exit 0;
  fi
fi

# Check if bitcoind process is running - start bitcoind if it's not running
# Only proceed if no lockfile is set
if [[ "$(pgrep "bitcoind" >> /dev/null && echo "Running")" != "Running" ]]; then
  if mkdir "${LOCK_DIR}"; then
    trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT;
    echo "Successfully acquired lock on "${LOCK_DIR}"";
    echo "bitcoind is not running...starting bitcoind";
    sudo -u "${BITCOIN_USER}" bitcoind -daemon >> /dev/null;
    rmdir "${LOCK_DIR}";
  else
    echo "Failed to acquire lock on "${LOCK_DIR}"";
    exit 0;
  fi
fi
