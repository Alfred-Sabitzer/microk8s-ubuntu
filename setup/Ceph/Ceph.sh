#!/bin/bash
############################################################################################
#
# Install and bootstrap a Ceph cluster using cephadm.
# Usage: ./Ceph.sh
# Prerequisites: Ubuntu 22.04+, passwordless sudo, SSH keys, cephadm installed.
#
############################################################################################
set -euo pipefail
trap 'echo "Script failed or exited early. Check logs and cleanup if needed."' EXIT

indir=$(dirname "$0")

# Check for required commands
for cmd in cephadm ceph; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed."
    exit 1
  fi
done

echo "Bootstrapping Ceph cluster..."
sudo cephadm bootstrap --mon-ip "$(hostname -I | awk '{print $1}')" \
  --allow-fqdn-hostname --no-cleanup-on-failure --allow-overwrite \
  --ssh-user alfred \
  --ssh-private-key /home/alfred/.ssh/id_rsa \
  --ssh-public-key /home/alfred/.ssh/id_rsa.pub \
  --initial-dashboard-user alfred \
  --initial-dashboard-password alfred

echo "Enabling telemetry and checking cluster status..."
sudo ceph telemetry on --license sharing-1-0
sudo ceph telemetry enable channel perf
sudo ceph status

echo "Adding hosts to the cluster..."
for host in k2 k3 k4; do
  ip=$(getent hosts $host | awk '{ print $1 }')
  if [ -z "$ip" ]; then
    echo "Warning: Could not resolve IP for $host, skipping."
    continue
  fi
  sudo ceph orch host add "$host" "$ip"
  sudo ceph orch host label add "$host" _admin
done

echo "Listing Ceph orchestrator processes..."
for host in k1 k2 k3 k4; do
  sudo ceph orch ps "$host"
done

echo "Ceph cluster installation complete."