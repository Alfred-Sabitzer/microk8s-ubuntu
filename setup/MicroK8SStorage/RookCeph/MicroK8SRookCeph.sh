#!/bin/bash
############################################################################################
#
# https://microk8s.io/docs/addon-rook-ceph
# https://github.com/rook/rook
# https://rook.io/docs/rook/latest-release/Getting-Started/intro/
# https://rook.io/docs/rook/latest-release/Getting-Started/quickstart/#deploy-the-rook-operator
# https://microk8s.io/docs/how-to-ceph
# https://docs.ceph.com/en/reef/
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-ceph-cluster-within-kubernetes-using-rook
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
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
  sudo snap install microceph --channel=latest/edge
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
sudo microceph status    
if [ $? -ne 0 ]; then
  echo "Error: microceph is not running. Please check the installation."
  exit 1
fi

# Configure microceph
sudo microceph client config set rbd_cache true
sudo microceph client config set rbd_cache false --target alpha
sudo microceph client config set rbd_cache_size 2048MiB --target beta
# This command lists the current configuration of the microceph cluster.
sudo microceph cluster config list

# Add virtual disks
sudo microceph disk add loop,4G,3


# Add a disk to the microceph cluster
if [ $? -ne 0 ]; then
  echo "Error: Failed to add disk to microceph cluster."
  exit 1
fi
echo "Disk added to microceph cluster successfully."

# Check the status of the microceph cluster
sudo microceph status
# Check the status of the microceph cluster to ensure it is healthy
if [ $? -ne 0 ]; then
  echo "Error: microceph cluster is not healthy. Please check the status."
  exit 1
fi
# List the disks in the microceph cluster
echo "Listing disks in the microceph cluster..."
sudo microceph disk list
# This command lists all the disks that are part of the microceph cluster.
# It will show the status of each disk, whether it is available, in use, or has any issues.
# If you see any disks that are not in the 'available' state, you may need to troubleshoot them.  

# Enable the RADOS Gateway (RGW) service
# This command enables the RGW service, which provides an object storage interface to the Ceph cluster.
# The RGW service allows you to use Ceph as an object storage system, similar to Amazon S3.
sudo microceph enable rgw
if [ $? -ne 0 ]; then
  echo "Error: Failed to enable RADOS Gateway (RGW) service."
  exit 1
fi
echo "RADOS Gateway (RGW) service enabled successfully."
# List the RGW instances in the microceph cluster
sudo microceph.rados lspools
# This command lists all the RADOS pools in the microceph cluster.


# This command lists all the RGW instances in the microceph cluster.
# It will show the status of each instance, whether it is running, stopped, or has any issues.
# If you see any instances that are not in the 'running' state, you may need to troubleshoot them.
# Create a new RGW user
#sudo microceph rgw user create --uid admin --display-name "Admin User" --email 

# Enable the microceph dashboard
sudo microceph.ceph mgr module ls

# This command enables the Ceph dashboard module, which provides a web-based interface to monitor and manage the Ceph cluster.
# It will also show the URL to access the dashboard.
sudo microceph.ceph config set mgr mgr/dashboard/ssl false 
sudo microceph.ceph mgr module enable dashboard 
echo -n "p@ssw0rd" | sudo tee /var/snap/microceph/current/conf/password.txt 
sudo microceph.ceph dashboard ac-user-create -i /var/snap/microceph/current/conf/password.txt admin administrator
sudo rm /var/snap/microceph/current/conf/password.txt

sudo microceph.ceph mgr services
# This command enables the Ceph dashboard module, which provides a web-based interface to monitor and manage the Ceph cluster.
# It will also show the URL to access the dashboard.
# Check if the dashboard is enabled
if ! sudo microceph.ceph mgr module ls | grep -i dashboard; then
  echo "Error: Ceph dashboard is not enabled."
  #exit 1
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

exit



# Now some additions
git clone --single-branch --branch v1.17.2 https://github.com/rook/rook.git

cd rook/deploy/examples
kubectl create -f crds.yaml -f common.yaml -f operator.yaml
#kubectl create -f cluster.yaml
# Go for the rigth cluster.yaml file
kubectl create -f cluster-test.yaml



helm install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph -f values.yaml


echo "Rook setup complete."



exit

# Add virtual disks

# The following loop creates three files under /mnt that will back respective loop devices. Each Virtual disk is then added as an OSD to Ceph:

# for l in a b c; do
#   loop_file="$(sudo mktemp -p /mnt XXXX.img)"
#   sudo truncate -s 1G "${loop_file}"
#   loop_dev="$(sudo losetup --show -f "${loop_file}")"
#   # the block-devices plug doesn't allow accessing /dev/loopX
#   # devices so we make those same devices available under alternate
#   # names (/dev/sdiY)
#   minor="${loop_dev##/dev/loop}"
#   sudo mknod -m 0660 "/dev/sdi${l}" b 7 "${minor}"
#   sudo microceph disk add --wipe "/dev/sdi${l}"
# done
