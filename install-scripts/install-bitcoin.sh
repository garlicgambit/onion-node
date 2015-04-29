#!/bin/bash
#
# Description:
# Install bitcoin from source
#
# TODO:
# - Automatically install latest stable bitcoin version
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
readonly BITCOIN_VERSION=v0.10.1
readonly ONION_DIR=/etc/onion-node
readonly GPG_KEYS="${ONION_DIR}"/install-scripts/download-gpg-keys.sh
readonly SRC_DIR=/usr/local/src/bitcoin
readonly BTC_URL=https://www.github.com/bitcoin/bitcoin.git
readonly SWAP_CONF=/etc/dphys-swapfile
readonly LOCK_DIR=/tmp/tor-bitcoin.lock/
readonly CPU_COUNT="$(nproc)"

# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script"
  exit 0
fi

# Check if a lockfile/LOCKDIR exists, wait max 30 minutes
tries=0
while [[ -d "${LOCK_DIR}" ]] && [[ "${tries}" -lt 30 ]]; do
  echo "Temporarily not able to acquire lock on ${LOCK_DIR}"
  echo "Other processes might be running...retry in 60 seconds"
  sleep 60
  tries=$(( ${tries} +1 ))
done

# Set lockfile/dir - mkdir is atomic
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT # remove LOCK_DIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on ${LOCK_DIR}"
else
  echo "Failed to acquire lock on ${LOCK_DIR}"
  echo "The installation script failed...run the install.sh script again to see if you get better results."
  echo "Tip: Reboot the system if the installation keeps failling."
  exit 0
fi

# Download latest GPG keys
"${GPG_KEYS}"

# Download latest version from github.com
echo "Download latest version from ${BTC_URL}"

tries=0
while [[ "${tries}" -lt 10 ]]; do
  if [[ -d "${SRC_DIR}" ]]; then
    echo "${SRC_DIR} already exits...downloading Bitcoin updates."
    cd "${SRC_DIR}"
    git fetch --all --tags && break
  else
    echo "Downloading full Bitcoin source code."
    git clone "${BTC_URL}" "${SRC_DIR}" && break
  fi
  sleep 30
  tries=$(( ${tries} +1 ))
  if [[ "${tries}" -eq 10 ]]; then
    echo "ERROR: The Bitcoin download script has failed."
    echo "The script will exit now."
    exit 0
  fi
done

echo "Downloaded latest Bitcoin version"

# Verify bitcoin source code
cd "${SRC_DIR}"
if git tag -v "${BITCOIN_VERSION}" 2>&1 >> /dev/null | grep -q "^gpg: Good signature from" && ! git tag -v "${BITCOIN_VERSION}" 2>&1 >> /dev/null | grep -q "^gpg: Bad signature from"; then
  echo "Good GPG signature...will continue bitcoin installation"
else
  echo "ERROR: Bad or missing GPG signature...exiting bitcoin installation"
  exit 0
fi

# Temporary increase swap size to 2 GB
echo "Temporary set swap to 2 GB to allow bitcoin to be compiled"
sed -i "s/CONF_SWAPSIZE\=100/CONF_SWAPSIZE\=2000/" "${SWAP_CONF}"
dphys-swapfile setup
dphys-swapfile swapon
echo "Swap set to 2GB"

# Compile and install bitcoin
# Build options:
# - no wallet
# - no gui
# - no upnp

echo "Installing bitcoin version ${BITCOIN_VERSION}"
cd "${SRC_DIR}"
git checkout "${BITCOIN_VERSION}"
./autogen.sh
./configure --disable-wallet --without-gui --without-miniupnpc

# Determine number of CPU's and set the number of jobs for make.
# Use 3 make jobs instead of 4. 3 jobs is about 1/4 faster then 4 jobs.
if [[ "${CPU_COUNT}" -gt 1 ]]; then
  echo "Number of available processors is: ${CPU_COUNT}"
  make_jobs=$(( ${CPU_COUNT} -1 ))
  echo "Building with ${make_jobs} make jobs"
else
  echo "Number of available processors is: ${CPU_COUNT}"
  make_jobs=$(( ${CPU_COUNT} ))
  echo "Building with ${make_jobs} make jobs"
fi

make --jobs "${make_jobs}"
make install
make clean
echo "Bitcoin is installed"

# Set swap size to default size
echo "Restore to default swap size...sleeping for 30 seconds to allow system to empty swap"
sleep 30
sed -i "s/CONF_SWAPSIZE\=2000/CONF_SWAPSIZE\=100/" "${SWAP_CONF}"
dphys-swapfile setup
dphys-swapfile swapon
echo "Swap set to default size"

echo "Bitcoin install script is done"
