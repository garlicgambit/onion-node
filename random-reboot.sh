#!/bin/bash
#
# Description:
# Automatically reboot the system every 2-4 weeks
# This is an unattended device, so a regular reboot might fix some system issues
#
# TODO:
# - Nothing yet
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
readonly MIN_TIME=1209600; # 1209600 seconds is 2 weeks
readonly MAX_TIME=2419200; # 2419200 seconds is 4 weeks
readonly RANDOM_TIME="$(shuf -i "${MIN_TIME}"-"${MAX_TIME}" -n 1)";
readonly LOCK_DIR=/tmp/randomreboot.lock/;
readonly LOCK_DIR2=/tmp/tor-bitcoin.lock/;


# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "${LOCK_DIR}"";
else
  echo "Failed to acquire lock on "${LOCK_DIR}"";
  exit 0;
fi

# Sleep for 2-4 weeks
echo "Sleeping for "${RANDOM_TIME}" seconds";
sleep "${RANDOM_TIME}";

# Check if other processes are running at this point
# Like:
# - re-installation of Onion node
# - building packages from source
# - Tor date check
#
# Check if a lockfile/LOCKDIR exists, wait max 2 hours
tries=0
while [[ -d "${LOCK_DIR2}" ]] && [[ "${tries}" -lt 120 ]]; do
  echo "Temporarily not able to acquire lock on "${LOCK_DIR}2"";
  echo "Other processes might be running...retry in 60 seconds";
  sleep 60;
  tries=$(( ${tries} +1 ));
done;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR2}"; then
  trap 'rmdir "${LOCK_DIR}"; rmdir "${LOCK_DIR2}"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "${LOCK_DIR2}"";
else
  echo "Failed to acquire lock on "${LOCK_DIR2}"";
  exit 0;
fi

# Reboot system in 5 minutes
# Give user a heads up and possibility to save work and/or cancel reboot
shutdown -r 5 "Cancel shutdown with: sudo shutdown -c";
