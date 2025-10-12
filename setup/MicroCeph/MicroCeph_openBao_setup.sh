#!/bin/bash
############################################################################################
#
# Configure Settings for OpenBao for Microceph
#
# https://github.com/openbao/openbao-csi-provider/tree/main/test/bats
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

indir="$(dirname "$0")"
my_namespace="openbao"

# Login????
#$ foo=${string#"$prefix"}
#$ foo=${foo%"$suffix"}
mymap=$(kubectl get configmaps -n openbao openbao-unseal-config -o yaml)
key=${mymap#*root_token: }  
roottoken=$(echo $key | cut -d " " -f 1)

echo $roottoken | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao login -

# 1. a) Openbao policies
cat <<EOF | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write s3-policy -
path "secret/data/s3/*" {
  capabilities = ["read"]
}
EOF

kubectl --namespace=openbao exec openbao-0 -- bao kv put secret/s3 s3=s3secret
kubectl --namespace=openbao exec openbao-0 -- bao kv get secret/s3 

# Create user for s3-Buckets
# This command creates a new user in the RADOS Gateway (RGW) service.
# The user will have access to the object storage interface provided by RGW.
sudo radosgw-admin user create --uid=s3admin --display-name="S3 Admin User" > s3admin_user.json
sudo radosgw-admin caps add --uid=s3admin --caps="buckets=*"

# Credentials in .s3cfg
# Configure s3cmd-tool

s3cmd --configure  

#
# This is from the admin_key.json file created above
#
# New settings:
#   Access Key: foo
#   Secret Key: bar
#   Default Region: AT
#   S3 Endpoint: s3.slainte.at:8081
#   DNS-style bucket+hostname:port template for accessing a bucket: alfred.s3.slainte.at:8081
#   Encryption password: mypersonalsecret
#   Path to GPG program: /usr/bin/gpg
#   Use HTTPS protocol: False
#   HTTP Proxy server name: 
#   HTTP Proxy server port: 0

# Test access with supplied credentials? [Y/n] Y
# Please wait, attempting to list all buckets...
# WARNING: Could not refresh role
# Success. Your access key and secret key worked fine :-)

# Now verifying that encryption works...
# Success. Encryption and decryption worked fine :-)

# Save settings? [y/N] y
# Configuration saved to '/home/alfred/.s3cfg'

# alfred@k8s:~$ s3cmd ls
# WARNING: Could not refresh role
# 2025-07-02 08:14  s3://alfred

# alfred@k8s:~$ s3cmd put -P /home/alfred/duesentrieb.jpg s3://alfred
# WARNING: Could not refresh role
# upload: '/home/alfred/duesentrieb.jpg' -> 's3://alfred/duesentrieb.jpg'  [1 of 1]
#  7771 of 7771   100% in    3s     2.23 KB/s  done
# Public URL of the object is: http://s3.slainte.at:8081/alfred/duesentrieb.jpg
# alfred@k8s:~$ s3cmd la s3://alfred
# WARNING: Could not refresh role
# WARNING: Could not refresh role
# 2025-07-02 08:22         7771  s3://alfred/duesentrieb.jpg

# alfred@k8s:~$ s3cmd get s3://alfred/duesentrieb.jpg ./test.jpg
# WARNING: Could not refresh role
# WARNING: Could not refresh role
# download: 's3://alfred/duesentrieb.jpg' -> './test.jpg'  [1 of 1]
#  7771 of 7771   100% in    0s     2.19 MB/s  done


# Encrypted Bucket über das Gui anlegen mit Token

s3cmd --bucket-location=":default-placement" mb s3://s3enc

s3cmd ls
s3cmd put -P /home/alfred/token.json s3://s3enc
s3cmd put -P /home/alfred/token.json s3://s3encrypted
s3cmd la s3://s3enc
s3cmd la s3://s3encrypted

s3cmd ls s3://s3enc

exit

# https://canonical-microceph.readthedocs-hosted.com/en/latest/how-to/mount-block-device/

 sudo rbd map \
    --image csi-vol-8459bcd2-5e9d-4229-9d2e-a0b0607b261c \
    --name client.admin \
    -m 192.168.178.200 \
    -k /var/snap/microceph/current/conf/ceph.keyring \
    -c /var/snap/microceph/current/conf/ceph.conf \
    -p microk8s-rbd0 \
    /dev/rbd0



# Encryption together wieth vault-provider doesn not really work

# https://docs.ceph.com/en/squid/radosgw/vault/

cat <<EOF | kubectl --namespace=${my_namespace} exec -i openbao-0 -- bao policy write rgw-kv-policy -
  path "secret/data/*" {
    capabilities = ["read"]
  }
EOF

# Generate Token

mytoken=$(kubectl --namespace=${my_namespace} exec openbao-0 -- bao token create -policy=rgw-kv-policy -type=service -display-name=rgw | grep -i  "token ")
mytoken=${mytoken#token}


rgw crypt vault secret engine = kv

sudo radosgw-admin  crypt vault auth = token
sudo radosgw-admin  crypt vault token file = /run/.rgw-vault-token
sudo radosgw-admin  crypt vault addr = https://vault-server-fqdn:8200
