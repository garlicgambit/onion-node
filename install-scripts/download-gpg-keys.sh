#!/bin/bash

# Download gpg keys

# To Do
# - check tlsdate gpg key
# - check sks-keyservers.net key

# gpg key bitcoin developer - Wladimir J. van der Laan
echo "Download gpg key bitcoin developer - Wladimir J. van der Laan";
gpg --recv-keys 71A3B16735405025D447E8F274810B012346C9A6
echo "Succesfully downloaded gpg key bitcoin developer - Wladimir J. van der Laan";

