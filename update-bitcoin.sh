#!/bin/bash
#
# Description:
# This script will update the Onion node to the latest stable Bitcoin release
# It will update at a random 1 to 10 day interval
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
readonly ONION_DIR=/etc/onion-node
readonly BITCOIN_INSTALL="${ONION_DIR}"/install-scripts/install-bitcoin.sh
readonly BITCOIN_SRC=/usr/local/src/bitcoin
readonly LOCK_DIR=/tmp/update-bitcoin.lock/
readonly LOCK_DIR2=/tmp/tor-bitcoin.lock/
readonly MIN_TIME=86400 # 864000 seconds is 1 day
readonly MAX_TIME=864000 # 864000 seconds is 10 days
readonly RANDOM_TIME="$(shuf -i "${MIN_TIME}"-"${MAX_TIME}" -n 1)"


# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script"
  exit 0
fi

# Set lockfile/dir - mkdir is atomic
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT # remove LOCK_DIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on ${LOCK_DIR}"
else
  echo "Failed to acquire lock on ${LOCK_DIR}"
  exit 0
fi

# Sleep for 1-10 days
echo "Sleeping for ${RANDOM_TIME} seconds"
sleep "${RANDOM_TIME}"

# Check if other processes are running at this point
# Like:
# - re-installation of Onion node
# - building packages from source
# - Tor date check
#
# Check if a lockfile/LOCKDIR2 exists, wait max 2 hours
tries=0
while [[ -d "${LOCK_DIR2}" ]] && [[ "${tries}" -lt 120 ]]; do
  echo "Temporarily not able to acquire lock on ${LOCK_DIR2}"
  echo "Other processes might be running...retry in 60 seconds"
  sleep 60
  tries=$(( ${tries} +1 ))
done

# Set lockfile/dir - mkdir is atomic
if mkdir "${LOCK_DIR2}"; then
  trap 'rmdir "${LOCK_DIR}"; rmdir "${LOCK_DIR2}"; exit' INT TERM EXIT # remove LOCK_DIR2 when script is interrupted, terminated or finished
  echo "Successfully acquired lock on ${LOCK_DIR2}"
else
  echo "Failed to acquire lock on ${LOCK_DIR2}"
  exit 0
fi

# Fetch latest Bitcoin updates
tries=0
while [[ "${tries}" -lt 10 ]]; do
  cd "${BITCOIN_SRC}"
  git fetch --all --tags && break
  sleep 30
  tries=$(( ${tries} +1 ))
  if [[ "${tries}" -eq 10 ]]; then
    echo "ERROR: The Bitcoin update has failed."
  fi
done

# Fetch latest Onion node updates
tries=0
while [[ "${tries}" -lt 10 ]]; do
  cd "${ONION_DIR}"
  git fetch --all --tags && break
  sleep 30
  tries=$(( ${tries} +1 ))
  if [[ "${tries}" -eq 10 ]]; then
    echo "ERROR: The Onion node update has failed."
  fi
done

# Select latest Onion node release/tag
LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
echo "Latest tag: ${LATEST_TAG}"

# Verify latest Onion node release/tag
cd "${ONION_DIR}"
if git tag -v "${LATEST_TAG}" 2>&1 >> /dev/null | grep -q "^gpg: Good signature from" && ! git tag -v "$BITCOINVERSION" 2>&1 >> /dev/null | grep -q "^gpg: Bad signature from"; then
  echo "Good GPG signature for latest Onion node release"
else
  echo "ERROR: Bad or missing GPG signature for latest Onion node release"
  echo "Warning: The Bitcoin client will not be upgraded to a new version"
  echo "The Bitcoin update script will exit now"
  exit 0
fi

# Check Bitcoin version between current branch/tag and the latest tag
if git diff "${LATEST_TAG}" "${BITCOIN_INSTALL}" | grep -q "^[+-]BITCOINVERSION="; then
  echo "A newer version of Bitcoin is available. This version will now be installed."
  echo "The update process might take 1 to 1.5 hours."
  git checkout "${LATEST_TAG}"
  rmdir "${LOCK_DIR2}"
  "${BITCOIN_INSTALL}"
else
  echo "Already running the latest bitcoin version"
fi
