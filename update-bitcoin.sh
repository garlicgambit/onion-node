#!/bin/bash

# This script will update the Onion node to the latest stable Bitcoin release
# It will update at a random 1 to 10 day interval

set -eu;

# Variables
ONIONDIR=/etc/onion-dir;
BITCOININSTALL="$ONIONDIR"/install-scripts/install-bitcoin.sh;
BITCOINSRC=/usr/local/src/bitcoin;
LOCKDIR=/tmp/update-bitcoin.lock/;
LOCKDIR2=/tmp/tor-bitcoin.lock/;
# 86400 seconds is 1 day, 864000 seconds is 10 days
MINTIME=86400;
MAXTIME=864000;
RANDOMTIME="$(shuf -i "$MINTIME"-"$MAXTIME" -n 1)";


# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script";
  exit 0;
fi

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "$LOCKDIR"; then
  trap 'rmdir "$LOCKDIR"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "$LOCKDIR"";
else
  echo "Failed to acquire lock on "$LOCKDIR"";
  exit 0;
fi

# Sleep for 1-10 days
echo "Sleeping for "$RANDOMTIME" seconds";
sleep "$RANDOMTIME";

# Check if other processes are running at this point
# Like:
# - re-installation of Onion node
# - building packages from source
# - Tor date check
#
# Check if a lockfile/LOCKDIR2 exists, wait max 2 hours
TRIES=0
while [[ -d "$LOCKDIR2" ]] && [[ "$TRIES" -lt 120 ]]; do
  echo "Temporarily not able to acquire lock on "$LOCKDIR2"";
  echo "Other processes might be running...retry in 60 seconds";
  sleep 60;
  TRIES=$(( $TRIES +1 ));
done;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "$LOCKDIR2"; then
  trap 'rmdir "$LOCKDIR2"; exit' INT TERM EXIT; # remove LOCKDIR2 when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "$LOCKDIR2"";
else
  echo "Failed to acquire lock on "$LOCKDIR2"";
  exit 0;
fi

# Fetch latest Bitcoin updates
TRIES=0;
while [[ "$TRIES" -lt 10 ]]; do
  cd "$BITCOINSRC";
  git fetch --all --tags && break;
  sleep 30;
  TRIES=$(( $TRIES +1 ));
  if [[ "$TRIES" -eq 10 ]]; then
    echo "ERROR: The Bitcoin update has failed.";
  fi
done;

# Fetch latest Onion node updates
TRIES=0;
while [[ "$TRIES" -lt 10 ]]; do
  cd "$ONIONDIR";
  git fetch --all --tags && break;
  sleep 30;
  TRIES=$(( $TRIES +1 ));
  if [[ "$TRIES" -eq 10 ]]; then
    echo "ERROR: The Onion node update has failed.";
  fi
done;

# Select latest Onion node release/tag
LATESTTAG=$(git describe --tags $(git revc-list --tags --max-count=1));
echo "Latest tag: "$LATESTTAG"";

# Verify latest Onion node release/tag
cd "$ONIONDIR";
if git tag -v "$LATESTTAG" 2>&1 >> /dev/null | grep -q "^gpg: Good signature from" && ! git tag -v "$BITCOINVERSION" 2>&1 >> /dev/null | grep -q "^gpg: Bad signature from"; then
  echo "Good GPG signature for latest Onion node release";
else
  echo "ERROR: Bad or missing GPG signature for latest Onion node release";
  echo "Warning: The Bitcoin client will not be upgraded to a new version";
  echo "The Bitcoin update script will exit now";
  exit 0;
fi

# Check Bitcoin version between current branch/tag and the latest tag
if git diff "$LATESTTAG" "$BITCOININSTALL" | grep -q "^[+-]BITCOINVERSION="; then
  echo "A newer version of Bitcoin is available. This version will now be installed.";
  echo "The update process might take 1 to 1.5 hours.";
  git checkout "$LATESTTAG";
  rmdir "$LOCKDIR2";
  "$BITCOININSTALL";
else
  echo "Already running the latest bitcoin version";
fi
