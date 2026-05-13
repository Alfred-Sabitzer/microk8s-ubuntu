#!/bin/bash
# creates trusted certificates
set -euo pipefail
# coyp the encryption config file to all nodes if it exists
ansible-playbook -v ./create_ca_certificate.yaml