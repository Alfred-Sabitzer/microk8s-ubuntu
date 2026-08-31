#!/bin/bash
############################################################################################
#
# Install and configure cosign https://docs.sigstore.dev/cosign/system_config/installation/
#
############################################################################################
set -euo pipefail
#shopt -o -s xtrace #—Displays each command before it is executed.

# install Cosign
# dkpg
LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_VERSION}_amd64.deb"
sudo dpkg -i cosign_${LATEST_VERSION}_amd64.deb

# Generate key
echo $HARBOR_MAINTAINER_PASSWORD | cosign generate-key-pair
#
