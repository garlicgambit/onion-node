#!/bin/bash
#
# Description:
# Install tlsdate from source
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
readonly SRC_DIR=/usr/local/src/tlsdate
readonly TLSDATE_URL=https://www.github.com/ioerror/tlsdate.git
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
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on ${LOCK_DIR}"
else
  echo "Failed to acquire lock on ${LOCK_DIR}"
  echo "The installation script failed...run the install.sh script again to see if you get better results."
  echo "Tip: Reboot the system if the installation keeps failling."
  exit 0
fi

# Download latest version from github.com
echo "Download latest tlsdate version from ${TLSDATE_URL}"
tries=0
while [[ "${tries}" -lt 10 ]]; do
  if [[ -d "${SRC_DIR}" ]]; then
    echo "${SRC_DIR} already exits...downloading tlsdate updates."
    cd "${SRC_DIR}"
    git fetch --all --tags && break
  else
    echo "Downloading full tlsdate source code."
    git clone "${TLSDATE_URL}" "${SRC_DIR}" && break
  fi
  sleep 30
  tries=$(( ${tries} +1 ))
  if [[ "${tries}" -eq 10 ]]; then
    echo "ERROR: The tlsdate download script has failed."
    echo "The script will exit now."
    exit 0
  fi
done

echo "Downloaded latest tlsdate version"

# Install tlsdate
echo "Installing tlsdate"
cd "${SRC_DIR}"
./autogen.sh
./configure

# Determine number of CPU's and set the number of jobs for make.
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
echo "tlsdate is installed"

echo "tlsdate install script is done"
