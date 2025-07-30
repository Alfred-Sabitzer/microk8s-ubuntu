#!/bin/bash
############################################################################################
#
# Enable ceph rados gateway (RGW) on the Ceph cluster.
# Usage: ./Ceph_rgw.sh
# Prerequisites: Ubuntu 22.04+, passwordless sudo, SSH keys, cephadm installed.
#
# https://docs.ceph.com/en/latest/cephadm/services/rgw/
# https://docs.ceph.com/en/quincy/mgr/rgw/
# https://docs.ceph.com/en/latest/radosgw/
# https://openmetal.io/resources/blog/setting-up-and-managing-ceph-rados-gateway-rgw-in-openstack/
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

RGW_INSTANCE_NAME="rgw.slainte"

# Enable the RGW module
sudo ceph mgr module enable rgw

# Create rgw keyring
echo "Creating keyring for RGW instance: ${RGW_INSTANCE_NAME}"
sudo ceph auth get-or-create client.${RGW_INSTANCE_NAME} osd 'allow rwx' mon 'allow rw' -o /etc/ceph/ceph.client.${RGW_INSTANCE_NAME}.keyring
# Set the right permissions
sudo chown ceph:ceph /etc/ceph/ceph.client.${RGW_INSTANCE_NAME}.keyring
sudo chmod 640 /etc/ceph/ceph.client.${RGW_INSTANCE_NAME}.keyring

# Change Configuration
echo "Updating Ceph configuration for RGW instance: ${RGW_INSTANCE_NAME}"
cat << EOF | sudo tee -a /etc/ceph/ceph.conf
[client.${RGW_INSTANCE_NAME}]
host = ${HOSTNAME}  # Or the specific hostname where this instance runs
keyring = /etc/ceph/ceph.client.${RGW_INSTANCE_NAME}.keyring
#rgw_frontends = "beast endpoint=0.0.0.0:7480" # Beast frontend listening on port 7480 (HTTP)
# For production, consider using HTTPS: "beast endpoint=0.0.0.0:7443 ssl_certificate=/path/to/cert.pem ssl_private_key=/path/to/key.pem"
rgw_frontends = "beast endpoint=0.0.0.0:4443 ssl_certificate=/etc/ssl/certs/server.crt ssl_private_key=/etc/ssl/private/server.key"
rgw_zone=at
rgw_data = /var/lib/ceph/radosgw/ceph-${RGW_INSTANCE_NAME} # Optional: Where RGW keeps its data
log_file = /var/log/ceph/ceph-rgw-${RGW_INSTANCE_NAME}.log
EOF

# Start rgw service
# Do this in the Dashboard

# https://docs.ceph.com/en/latest/radosgw/multisite/
sudo radosgw-admin user create --uid="radosgwadmin" --display-name="Admin for Rados Gateway" --system

sudo radosgw-admin realm create --rgw-realm=slainte --default
sudo radosgw-admin zone modify --rgw-zone=slainte --access-key=SY7ONOGO0A2EOBNUSNV4 --secret=kB1OAEKOg3y4rR6T8KRuTwiv6lKn3578OXSEGnqH
sudo radosgw-admin period update --commit

# Check if RGW is running
sudo ceph orch ps --daemon_type rgw 
# List RGW users
sudo radosgw-admin user list --uid=radosgwadmin
# List RGW zones
sudo radosgw-admin zone list
# List RGW realms
sudo radosgw-admin realm list

            "access_key": "SY7ONOGO0A2EOBNUSNV4",
            "secret_key": "kB1OAEKOg3y4rR6T8KRuTwiv6lKn3578OXSEGnqH",


sudo rados df







#https://docs.ceph.com/en/latest/mgr/dashboard/#enabling-the-object-gateway-management-frontend
sudo ceph dashboard set-rgw-credentials
sudo ceph dashboard set-rgw-api-admin-resource radosgwadmin
sudo ceph dashboard set-rgw-api-ssl-verify False


# https://ceph.io/en/news/blog/2025/simplifying-object-new-cephadm/

sudo ceph mgr module enable rgw

cat << EOF > ~/rgw-client.spec
service_type: rgw
service_id: client
service_name: rgw.client
placement:
  label: rgw
  count_per_host: 1
networks:
  - $(hostname -i)/24
spec:
  rgw_frontend_port: 4443
  rgw_realm: multisite
  rgw_zone: zone1
  rgw_zonegroup: multizg
  generate_cert: true
  ssl: true
  zonegroup_hostnames:
    - s3.slainte.at
  data_pool_attributes:
    type: ec
    k: 2
    m: 2
extra_container_args:
  - "--stop-timeout=120"
config:
  rgw_exit_timeout_secs: "120"
  rgw_graceful_stop: true
EOF

sudo ceph rgw realm bootstrap -i ~/rgw-client.spec


echo "Ceph Rados Gateway (RGW) setup complete."


#############################
# Nach graphischem Setup


sudo ceph dashboard set-rgw-credentials
sudo ceph dashboard set-rgw-api-ssl-verify False
