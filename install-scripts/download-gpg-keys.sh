#!/bin/bash

# Download gpg keys

# To Do
# - check tlsdate gpg key
# - check sks-keyservers.net key


# Download gpg key Onion-node developer - Jules Mercier
TRIES=0;
while [[ "$TRIES" -lt 10 ]]; do
  echo "Download gpg key onion-node developer Jules Mercier";
  gpg --recv-keys 4B8BBB5F5F2238A0BD72BE97F7698FEE3295ABB5 && break;
  sleep 30;
  TRIES=$(( $TRIES +1 ));
  if [[ "$TRIES" -eq 10 ]]; then
    echo "ERROR: Downloading GPG key has failed.";
    echo "The script will exit now.";
    exit 0;
  fi
done;

# Download gpg key Bitcoin developer - Wladimir J. van der Laan
TRIES=0;
while [[ "$TRIES" -lt 10 ]]; do
  echo "Download gpg key bitcoin developer - Wladimir J. van der Laan";
  gpg --recv-keys 71A3B16735405025D447E8F274810B012346C9A6 && break;
  sleep 30;
  TRIES=$(( $TRIES +1 ));
  if [[ "$TRIES" -eq 10 ]]; then
    echo "ERROR: Downloading GPG key has failed.";
    echo "The script will exit now.";
    exit 0;
  fi
done;
