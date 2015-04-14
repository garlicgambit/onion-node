#!/bin/bash

set -eu

# Automatically reboot the system every 2-4 weeks
# This is an unattended device, so a regular reboot might fix some system issues

# To do:
# - Nothing yet

# Variables

# 1209600 seconds is 2 weeks, 2419200 seconds is 4 weeks
MINTIME=1209600;
MAXTIME=2419200;
RANDOMTIME="$(shuf -i "$MINTIME"-"$MAXTIME" -n 1)";
LOCKDIR=/tmp/randomreboot.lock/;
LOCKDIR2=/tmp/tor-bitcoin.lock/;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "$LOCKDIR"; then
  trap 'rmdir "$LOCKDIR"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "$LOCKDIR"";
else
  echo "Failed to acquire lock on "$LOCKDIR"";
  exit 0;
fi

# Sleep for 2-4 weeks
echo "Sleeping for "$RANDOMTIME" seconds";
sleep "$RANDOMTIME";

# Check if other processes are running at this point
# Like:
# - re-installation of Onion node
# - building packages from source
# - Tor date check
#
# Check if a lockfile/LOCKDIR exists, wait max 2 hours
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
  trap 'rmdir "$LOCKDIR2"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "$LOCKDIR2"";
else
  echo "Failed to acquire lock on "$LOCKDIR2"";
  exit 0;
fi

# Reboot system in 5 minutes
# Give user a heads up and possibility to save work and/or cancel reboot
shutdown -r 5 "Cancel shutdown with: sudo shutdown -c";
