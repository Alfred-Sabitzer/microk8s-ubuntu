#!/bin/bash
############################################################################################
#
# Configure keepassxc
#
# https://keepassxc.org/docs/#/usage/cli
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

cat <<EOF
# Python and virtual environment are required to run the following commands. Please ensure you have Python installed and a virtual environment set up before proceeding.
EOF

source .venv/bin/activate
python -m pip install pykeepass
python -m pip install pyyaml

cat <<EOF
# Virtual environment activated and required packages installed. You can now run the following commands to interact with your KeePassXC database.
python keepass_to_eso_openbao.py \
    --kdbx ./python.kdbx \
    --password "your_database_password" \
    --outdir "./test" \
    --store-name "openbao" \
    --store-kind "ClusterSecretStore" \
    --refresh "1h" \
    --mount "kv" \
    --prefix "k8s" \
    --export-openbao "yaml"
EOF
#