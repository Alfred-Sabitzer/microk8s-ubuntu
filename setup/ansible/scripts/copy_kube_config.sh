#!/bin/bash
# copy ~/.kube/config to all other nodes
set -euo pipefail
# coyp the encryption config file to all nodes if it exists
ansible-playbook -v ./copy_kube_config_get.yaml
ansible-playbook -v ./copy_kube_config_put.yaml