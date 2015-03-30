#!/bin/bash

# This script is used to set (fresh) values in bitcoin.conf file

# To Do
# - Integrate while loop to check if /tmp/hidden_service/hostname exists with 'sed'ting the new hostname in the bitcoin.conf file

export RANDFILE=/etc/node-scripts/.rnd;

# Variables

# Location of bitcoin.conf file
BITCOINFILE=/home/pi/.bitcoin/bitcoin.conf;

# rpcpassword variables
OPENSSLKEY="$(openssl rand -base64 48)";
NEWRPCPASSWORD="$(echo -n "$OPENSSLKEY" | sha256sum | head -c 64)";
OLDRPCPASSWORD=CHANGETHISPASSWORD;

# externalip variables
EXTERNALIP=externalip=;


# Stop bitcoin process - execute bitcoin-control.sh script
echo "Stopping bitcoin process";
/etc/node-scripts/bitcoin-control.sh;
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
TRIES=0
while [[ ! -r /tmp/hidden_service/hostname ]] && [[ "$TRIES" -lt 10 ]]; do
  echo "Tor hostname not available...waiting for 30 seconds";
  sleep 30;
  TRIES=$(( $TRIES +1 ));
  if [[ $TRIES -eq 5 ]]; then
    echo "Tor hidden service not created yet...restarting Tor";
    /etc/init.d/tor restart;
    sleep 30;
  fi
  if [[ $TRIES -eq 10 ]]; then
    echo "Tor hidden service not created properly...exiting script";
    exit 0;
  fi
done;

# Change rpcpassword
sed -i "s/$OLDRPCPASSWORD/$NEWRPCPASSWORD/" "$BITCOINFILE";

# Change externalip
TORHOSTNAME="$( </tmp/hidden_service/hostname )";
sed -i "s,^\("$EXTERNALIP"\).*,\1"$TORHOSTNAME"," "$BITCOINFILE";

# Start bitcoin process again
echo "Starting bitcoind process";
sudo -u pi bitcoind -daemon >> /dev/null;
echo "bitcoind process started";
