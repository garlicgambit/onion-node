#!/bin/bash

# Download gpg keys

# To Do
# - check tlsdate gpg key
# - check sks-keyservers.net key

# gpg key onion-node developer Jules Mercier
echo "Download gpg key onion-node developer Jules Mercier";
gpg --recv-keys 4B8BBB5F5F2238A0BD72BE97F7698FEE3295ABB5
echo "Successfully downloaded gpg key onion node developer - Jules Mercier";

# gpg key bitcoin developer - Wladimir J. van der Laan
echo "Download gpg key bitcoin developer - Wladimir J. van der Laan";
gpg --recv-keys 71A3B16735405025D447E8F274810B012346C9A6
echo "Succesfully downloaded gpg key bitcoin developer - Wladimir J. van der Laan";

