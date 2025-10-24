#!/bin/bash
# copy /var/snap/microk8s/current/args/encryption-config to all other nodes
set -euo pipefail
# coyp the encryption config file to all nodes if it exists
ansible-playbook -v ./copy_encryption_config_get.yaml
ansible-playbook -v ./copy_encryption_config_put.yaml