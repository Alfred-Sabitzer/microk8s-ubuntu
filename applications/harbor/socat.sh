#!/bin/bash
############################################################################################
#
# Install and configure socat https://linux.die.net/man/1/socat
#
############################################################################################
set -euo pipefail
#shopt -o -s xtrace #—Displays each command before it is executed.

# install socat
sudo apt-get install -y socat

# Start socat
sudo socat OPENSSL-LISTEN:5000,fork,cert=/etc/containers/certs.d/harbor.test.slainte.at/local.crt,key=/etc/containers/certs.d/harbor.test.slainte.at/local.key,verify=0 OPENSSL:harbor.test.slainte.at:443,cert=/etc/containers/certs.d/harbor.test.slainte.at/client.cert,key=/etc/containers/certs.d/harbor.test.slainte.at/client.key,verify=0 &
#
