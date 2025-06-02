#!/bin/bash
############################################################################################
#
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
indir=$(dirname "$0")

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

# check if microceph is installed
if ! command -v microceph &> /dev/null; then
  echo "microceph is not installed. Installing..."
  # Install microceph snap package
  sudo snap install microceph
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install microceph."
    exit 1
  fi
  # Hold the snap package to prevent automatic updates
  sudo snap refresh --hold microceph

  echo "microceph installed successfully."
  echo "Bootstrapping microceph cluster..."
  # Bootstrap the microceph cluster
  # This command will initialize the Ceph cluster
  # and set up the necessary configurations.
  # Make sure to run this command only once
  # when setting up the cluster for the first time.
  # If you run it again, it will fail.
  echo "Running: sudo microceph cluster bootstrap"
  sudo microceph cluster bootstrap
else
  echo "microceph is already installed."
fi

# Check if microceph is running
sudo microceph.ceph status
if [ $? -ne 0 ]; then
  echo "Error: microceph is not running. Please check the installation."
  exit 1
fi

# To use MicroCeph as a single node, the default CRUSH rules need to be modified: 
sudo microceph.ceph osd crush rule rm replicated_rule
sudo microceph.ceph osd crush rule create-replicated single default osd

# Now createe Disk-Encryption

# chek if dm-crypt is available
if ! command -v dmsetup &> /dev/null; then
  echo "dmsetup is not installed. Please install it to proceed."
  exit 1
fi
sudo modinfo dm-crypt
sudo snap connect microceph:dm-crypt
sudo snap restart microceph.daemon

# Now add encrypted disks
for l in a b c; do
  loop_file="$(sudo mktemp -p /mnt XXXX.img)"
  sudo truncate -s 1G "${loop_file}"
  loop_dev="$(sudo losetup --show -f "${loop_file}")"
  # the block-devices plug doesn't allow accessing /dev/loopX
  # devices so we make those same devices available under alternate
  # names (/dev/sdiY)
  minor="${loop_dev##/dev/loop}"
  sudo rm -f "/dev/sdi${l}"
  sudo mknod -m 0660 "/dev/sdi${l}" b 7 "${minor}"
  sudo microceph disk add --wipe --encrypt "/dev/sdi${l}"
  sudo microceph.ceph status
  sudo microceph.ceph osd status
done

echo "Listing disks in the microceph cluster..."
sudo microceph disk list

# Check devices on the system
echo "Listing block devices on the system..."
lsblk | grep -v loop
echo "Disk added to microceph cluster successfully."


# Enable the RADOS Gateway (RGW) service
# RBD (RADOS Block Device) is a block storage interface for Ceph.
# It allows you to create block devices that can be used by applications or virtual machines.
# This command enables the RGW service, which provides an object storage interface to the Ceph cluster.
# The RGW service allows you to use Ceph as an object storage system, similar to Amazon S3.
sudo microceph enable rgw --target $(hostname) --port 8081
#sudo microceph enable rgw
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

# Configure s3cmd-tool
s3cmd --configure  

#
# This is from the admin_key.json file created above
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


# still not working s3cmd mb -P s3://mybucket

# still not working s3cmd put -P image.jpg s3://mybucket


# List the RGW instances in the microceph cluster
# This command lists all the RADOS pools in the microceph cluster
# It will show the status of each pool, whether it is available, in use, or has any issues.
# If you see any pools that are not in the 'available' state, you may need to troubleshoot them.
sudo microceph.rados lspools

# this is for mirroring in a real cluster

# # This command enables the RBD service, which provides block storage capabilities to the Ceph cluster.
# sudo microceph enable rbd-mirror
# if [ $? -ne 0 ]; then
#   echo "Error: Failed to enable RBD service."
#   exit 1
# fi
# echo "RBD service enabled successfully."
# # This command lists all the RBD pools in the microceph cluster.
# # It will show the status of each pool, whether it is available, in use, or has any issues.
# # If you see any pools that are not in the 'available' state, you may need to troubleshoot them.
# # List the RBD pools in the microceph cluster

# # Configure microceph
# sudo microceph client config set rbd_cache true
# sudo microceph client config set rbd_cache false --target alpha
# sudo microceph client config set rbd_cache_size 2048MiB --target beta
# sudo microceph client config list --target beta
# sudo microceph cluster config rbd_cache --target alpha

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

sudo microceph.ceph mgr services
# This command enables the Ceph dashboard module, which provides a web-based interface to monitor and manage the Ceph cluster.
# It will also show the URL to access the dashboard.
# Check if the dashboard is enabled
if ! sudo microceph.ceph mgr module ls | grep -i dashboard; then
  echo "Error: Ceph dashboard is not enabled."
  exit 1
fi
# Get the dashboard URL
sudo microceph.ceph mgr services 

# Install the Rook operator
echo "Disabling Rook..."
microk8s disable rook-ceph || true

echo "Enabling Rook..."
microk8s enable rook-ceph
helm ls --namespace rook-ceph
kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator"

# Wait for the Rook operator to be ready   
echo "Waiting for Rook operator to be ready..."
microk8s kubectl wait --for=condition=Ready pod -l app=rook-ceph-operator --namespace rook-ceph --timeout=300s

sudo microk8s helm repo add rook-release https://charts.rook.io/release
sudo microk8s helm repo update

# Connect to the external Ceph cluster
echo "Connecting to external Ceph cluster..."
# This command connects the Rook operator to an existing Ceph cluster.
# It assumes that the Ceph cluster is already set up and running.
# Make sure to replace 'ceph-cluster' with the actual name of your Ceph cluster.
sudo microk8s connect-external-ceph

kubectl --namespace rook-ceph-external get cephcluster

# List the storage classes in the cluster
echo "Listing storage classes..."
kubectl get storageclasses.storage.k8s.io

#echo "Patching storage classes to set ceph as default..."
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

echo "Verifying storage classes..."
microk8s kubectl get storageclasses.storage.k8s.io

echo "Rook setup complete."


# https://forum.proxmox.com/threads/ceph-luks-password.94868/


sudo microceph cluster sql "SELECT name FROM sqlite_master WHERE type='table';"

sudo cryptsetup luksDump /dev/sdia 
LUKS header information
Version:       	2
Epoch:         	3
Metadata area: 	16384 [bytes]
Keyslots area: 	16744448 [bytes]
UUID:          	c523bbee-3db4-4241-ab6d-b678d88f9c98
Label:         	(no label)
Subsystem:     	(no subsystem)
Flags:       	(no flags)

Data segments:
  0: crypt
	offset: 16777216 [bytes]
	length: (whole device)
	cipher: aes-xts-plain64
	sector: 512 [bytes]

Keyslots:
  0: luks2
	Key:        512 bits
	Priority:   normal
	Cipher:     aes-xts-plain64
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  5
	Memory:     1048576
	Threads:    4
	Salt:       3e 0d 6c 80 c1 17 06 e4 79 b8 ec ea 6c bf 7f e6 
	            3a f0 f8 1e d9 7d b6 f1 cb 9c 4d dc ff 51 8f 80 
	AF stripes: 4000
	AF hash:    sha256
	Area offset:32768 [bytes]
	Area length:258048 [bytes]
	Digest ID:  0
Tokens:
Digests:
  0: pbkdf2
	Hash:       sha256
	Iterations: 96518
	Salt:       45 3c 38 0f 3e ab ca 01 49 bf 03 bb 19 db 94 ed 
	            45 1b a9 68 87 8a ae 06 fd 01 1c 5e 0b ae 71 9f 
	Digest:     66 d4 43 d4 4e 94 a0 be 9c 7a 86 67 8b ce 63 2f 
	            3d 11 66 a1 01 fb a7 24 a3 f4 dc 5c 53 03 32 9e 


exit
