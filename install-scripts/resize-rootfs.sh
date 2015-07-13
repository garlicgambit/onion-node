#!/bin/bash
#
# Description:
# Automatically resize the root filesystem to the SD card size.
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
readonly BITCOIN_USER=bitcoinuser
readonly LOCK_DIR=/home/"${BITCOIN_USER}"/resize-rootfs.lock/


# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script"
  exit 0
fi

# Resize root filesystem once
if [[ ! -d "${LOCK_DIR}" ]]; then
  echo "${LOCK_DIR} does not exist...will resize root filesystem"
  # Expand root filesystem
  /usr/bin/raspi-config --expand-rootfs
  # Set lockfile
  mkdir -p "${LOCK_DIR}"
  # Reboot system after 1 minute
  shutdown -r 1
fi
