#!/bin/bash
#
# Description:
# Automatically install system updates at a random interval
#
# TODO:
# - Nothing yet...
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
readonly MIN_TIME=0;
readonly MAX_TIME=216000; # 216000 seconds is 5 days
readonly RANDOM_TIME="$(shuf -i "${MIN_TIME}"-"${MAX_TIME}" -n 1)";
readonly LOCKDIR=/tmp/random-unattended-upgrades.lock/;


# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "${LOCK_DIR}"";
else
  echo "Failed to acquire lock on "${LOCK_DIR}"";
  exit 0;
fi

# Random sleep
echo "Sleeping for "${RANDOM_TIME}" seconds";
sleep "${RANDOM_TIME}";

# Update repositories
apt-get update;

# Install system updates
unattended-upgrades;
