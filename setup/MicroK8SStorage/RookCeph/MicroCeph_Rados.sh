#!/bin/bash
############################################################################################
#
# Enable the RADOS Gateway (RGW) service
# RBD (RADOS Block Device) is a block storage interface for Ceph.
# It allows you to create block devices that can be used by applications or virtual machines.
# This command enables the RGW service, which provides an object storage interface to the Ceph cluster.
# The RGW service allows you to use Ceph as an object storage system, similar to Amazon S3.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail


sudo microceph enable rgw --target $(hostname) --port 8081
if [ $? -ne 0 ]; then
  echo "Error: Failed to enable RADOS Gateway (RGW) service."
  exit 1
fi
echo "RADOS Gateway (RGW) service enabled successfully."

# This command creates a new user in the RADOS Gateway (RGW) service.
# The user will have access to the object storage interface provided by RGW.
sudo radosgw-admin user create --uid=admin --display-name="Admin User" > admin_user.json
sudo radosgw-admin key create --uid=admin --key-type=s3 --access-key=foo --secret-key=bar > admin_key.json

# https://canonical-microceph.readthedocs-hosted.com/en/squid-stable/tutorial/get-started/
sudo microceph status
curl http://$(hostname -I | awk '{print $1}'):8081
# <?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>anonymous</ID></Owner><Buckets></Buckets></ListAllMyBucketsResult>

# Configure s3cmd-tool
s3cmd --configure  

#
# New settings:
#   Access Key: foo
#   Secret Key: bar
#   Default Region: at
#   S3 Endpoint: 192.168.178.200:8081
#   DNS-style bucket+hostname:port template for accessing a bucket: %(bucket)s.192.168.178.200:8081
#   Encryption password: PES8OPI1W5P0UOK86QM7
#   Path to GPG program: /usr/bin/gpg
#   Use HTTPS protocol: False
#   HTTP Proxy server name: 
#   HTTP Proxy server port: 0
#
# Test access with supplied credentials? [Y/n] Y
# Please wait, attempting to list all buckets...
# WARNING: Could not refresh role
# Success. Your access key and secret key worked fine :-)
#
# Now verifying that encryption works...
# Success. Encryption and decryption worked fine :-)
#
# Save settings? [y/N] y
# Configuration saved to '/home/alfred/.s3cfg'



# still not working s3cmd mb -P s3://mybucket
# WARNING: Could not refresh role
# ERROR: [Errno -2] Name or service not known
# ERROR: Connection Error: Error resolving a server hostname.
# Please check the servers address specified in 'host_base', 'host_bucket', 'cloudfront_host', 'website_endpoint'

s3cmd ls


# still not working s3cmd put -P Daniel.png s3://alfred
s3cmd info s3://alfred  



# List the RGW instances in the microceph cluster
# This command lists all the RADOS pools in the microceph cluster
# It will show the status of each pool, whether it is available, in use, or has any issues.
# If you see any pools that are not in the 'available' state, you may need to troubleshoot them.
sudo microceph.rados lspools


exit


curl -X POST "http://k8s.slainte.at:8080/api/auth" \
-H  "Accept: application/vnd.ceph.api.v1.0+json" \
-H  "Content-Type: application/json" \
-d '{"username": admin, "password": p@ssw0rd}'



curl -X GET "https://example.com:8443/api/osd" \
-H  "Accept: application/vnd.ceph.api.v1.0+json" \
-H  "Authorization: Bearer <token>"

