#!/bin/bash
############################################################################################
#
# Install dashboard for microceph
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

# Enable the microceph dashboard
sudo microceph.ceph mgr module ls
# This command enables the Ceph dashboard module, which provides a web-based interface to monitor and manage the Ceph cluster.
# It will also show the URL to access the dashboard.
sudo microceph.ceph mgr module enable dashboard 
#sudo microceph.ceph dashboard create-self-signed-cert
sudo microceph.ceph config set mgr mgr/dashboard/ssl false 
echo -n "p@ssw0rd" | sudo tee /var/snap/microceph/current/conf/password.txt 
sudo microceph.ceph dashboard ac-user-create -i /var/snap/microceph/current/conf/password.txt admin administrator
sudo rm /var/snap/microceph/current/conf/password.txt

# ceph config set mgr mgr/dashboard/$name/server_addr $IP
# ceph config set mgr mgr/dashboard/$name/server_port $PORT
# ceph config set mgr mgr/dashboard/$name/ssl_server_port $PORT

# This command enables the Ceph dashboard module, which provides a web-based interface to monitor and manage the Ceph cluster.
# It will also show the URL to access the dashboard.
# Check if the dashboard is enabled
if ! sudo microceph.ceph mgr module ls | grep -i dashboard; then
  echo "Error: Ceph dashboard is not enabled."
  exit 1
fi
# Get the dashboard URL
sudo microceph.ceph mgr services 