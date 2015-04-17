#!/bin/bash

set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set

# This script is used to set (fresh) values in bitcoin.conf file

# To Do
# - Integrate while loop to check if /tmp/hidden_service/hostname exists with 'sed'ting the new hostname in the bitcoin.conf file
# - A presumably 'stale' lockfile/LOCKDIR is removed after 2 hours. Look into a more elegant solution.

export RANDFILE=/etc/onion-node/.rnd;

# Variables

readonly ONION_DIR=/etc/onion-node;
readonly BITCOIN_USER=bitcoinuser;
# Location of bitcoin.conf file
readonly BITCOIN_FILE=/home/"${BITCOIN_USER}"/.bitcoin/bitcoin.conf;

# rpcpassword variables
readonly OPENSSL_KEY="$(openssl rand -base64 48)";
readonly NEW_RPC_PASSWORD="$(echo -n "${OPENSSL_KEY}" | sha256sum | head -c 64)";
readonly OLD_RPC_PASSWORD=CHANGETHISPASSWORD;

# externalip variables
readonly EXTERNAL_IP=externalip=;

readonly LOCK_DIR=/tmp/tor-bitcoin.lock/;


# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script";
  exit 0;
fi

# Check if a lockfile/LOCKDIR exists, wait max 2 hours to remove 'stale' lockfile and exit script
tries=0
while [[ -d "${LOCK_DIR}" ]] && [[ "${tries}" -lt 120 ]]; do
  echo "Temporarily not able to acquire lock on "${LOCK_DIR}"";
  echo "Other processes might be running...retry in 60 seconds";
  sleep 60;
  tries=$(( ${tries} +1 ));
  if [[ $tries -eq 120 ]]; then
    echo "ERROR: After 2 hours the "${LOCK_DIR}" still exists";
    echo "Not a good sign";
    echo "Removing presumably stale "${LOCK_DIR}"";
    rmdir "${LOCK_DIR}";
  fi
done;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "${LOCK_DIR}"";
else
  echo "Failed to acquire lock on "${LOCK_DIR}"";
  exit 0;
fi

# Stop bitcoin process - execute bitcoin-control.sh script
echo "Stopping bitcoin process";
"${ONION_DIR}"/bitcoin-control.sh;
echo "Bitcoin process has quit";

# Change .onion address
echo "Stopping tor to create new .onion address";
/etc/init.d/tor stop;
echo "Sleeping for 30 seconds to let the Tor process stop smoothly";
sleep 30;
rm -rf /tmp/hidden_service;
sleep 5;
echo "Starting tor for new .onion address";
/etc/init.d/tor start;
echo "Sleeping for 30 seconds to let the Tor process start smoothly";
sleep 30;

# Check if Tor hostname file exists, if not sleep for a while
tries=0
while [[ ! -r /tmp/hidden_service/hostname ]] && [[ "${tries}" -lt 10 ]]; do
  echo "Tor hostname not available...waiting for 30 seconds";
  sleep 30;
  tries=$(( ${tries} +1 ));
  if [[ $tries -eq 5 ]]; then
    echo "Tor hidden service not created yet...restarting Tor";
    /etc/init.d/tor restart;
    sleep 30;
  fi
  if [[ $tries -eq 10 ]]; then
    echo "Tor hidden service not created properly...exiting script";
    exit 0;
  fi
done;

# Change rpcpassword
sed -i "s/"${OLD_RPC_PASSWORD}"/"${NEW_RPC_PASSWORD}"/" "${BITCOIN_FILE}";

# Change externalip
TORHOSTNAME="$( </tmp/hidden_service/hostname )";
sed -i "s,^\("$EXTERNALIP"\).*,\1"$TORHOSTNAME"," "${BITCOIN_FILE}";

# Start bitcoin process again
echo "Starting bitcoind process";
sudo -u "${BITCOIN_USER}" bitcoind -daemon >> /dev/null;
echo "bitcoind process started";
