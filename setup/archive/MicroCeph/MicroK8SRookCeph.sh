#!/bin/bash
############################################################################################
#
# Install and configure MicroCeph on MicroK8s
# Aim is to have encrypted disks, based on secrets in openbao
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
indir=$(dirname "$0")

echo "Checking if sudo microk8s is installed..."
if ! command -v sudo microk8s &> /dev/null; then
  echo "Error: sudo microk8s is not installed."
  exit 1
fi

# remove old microceph snap package if it exists
if snap list | grep -q microceph; then
  echo "Removing old microceph snap package..."
  sudo snap remove microceph --purge  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to remove old microceph snap package."
    exit 1
  fi
  echo "Old microceph snap package removed successfully."
else
  echo "No old microceph snap package found."
fi

# check if microceph is installed
if ! which microceph &> /dev/null; then
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

# Now create Disk-Encryption
# https://documentation.ubuntu.com/microcloud/latest/microceph/explanation/security/full-disk-encryption/


# chek if dm-crypt is available
if ! command -v dmsetup &> /dev/null; then
  echo "dmsetup is not installed. Please install it to proceed."
  exit 1
fi
sudo modinfo dm-crypt
sudo snap connect microceph:dm-crypt
sudo snap restart microceph.daemon


# Now add encrypted disks
# for l in a b c; do
#   sudo rm -f "/dev/sdi${l}"
#   loop_file="$(sudo mktemp -p /mnt XXXX.img)"
#   sudo truncate -s 1G "${loop_file}"
#   loop_dev="$(sudo losetup --show -f "${loop_file}")"
#   # the block-devices plug doesn't allow accessing /dev/loopX
#   # devices so we make those same devices available under alternate
#   # names (/dev/sdiY)
#   minor="${loop_dev##/dev/loop}"
#   sudo mknod -m 0660 "/dev/sdi${l}" b 7 "${minor}"
#   sudo microceph disk add --wipe --encrypt "/dev/sdi${l}"
# done

sudo microceph disk add loop,4G,3 --encrypt --wipe --verbose
sudo microceph.ceph status
sudo microceph.ceph osd status

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
#sudo radosgw-admin key create --uid=admin --key-type=s3 --access-key=foo --secret-key=bar > admin_key.json

# https://canonical-microceph.readthedocs-hosted.com/en/squid-stable/tutorial/get-started/
sudo microceph status
sudo netstat -tulpen | grep -i rados
sleep 15
curl http://$(hostname -I | awk '{print $1}'):8081


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
sudo microceph.ceph config set mgr mgr/dashboard/server_port 8081
sudo microceph.ceph mgr module enable dashboard 
#sudo microceph.ceph dashboard create-self-signed-cert

#sudo microceph.ceph config set mgr mgr/dashboard/server_addr $IP
#sudo microceph.ceph config set mgr mgr/dashboard/server_port 8081
#sudo microceph.ceph config set mgr mgr/dashboard/ssl_server_port $PORT

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

# alfred@k8s:~$ sudo ls -lah /dev/disk/by-uuid/
# alfred@k8s:~$ lsblk | grep --encrypt -v loop
# alfred@k8s:~$ sudo parted /dev/sda print
# alfred@k8s:~$ sudo ls /dev/mapper/ -lisa
# alfred@k8s:~$ sudo parted /dev/dm-0 print

# alfred@k8s:~$ ps -ef |  grep -i rad
# root        1297       1  0 08:53 ?        00:00:00 /usr/bin/python3 /usr/share/unattended-upgrades/unattended-upgrade-shutdown --wait-for-signal
# root       98211       1  1 09:27 ?        00:00:02 radosgw -f --cluster ceph --name client.radosgw.gateway -c /var/snap/microceph/1393/conf/radosgw.conf
# alfred    119367   97016  0 09:30 pts/0    00:00:00 grep --color=auto -i rad

# alfred@k8s:~$ sudo cat /var/snap/microceph/1393/conf/radosgw.conf
# # Generated by MicroCeph, DO NOT EDIT.
# [global]
# mon host = 192.168.178.200
# run dir = /var/snap/microceph/1393/run
# auth allow insecure global id reclaim = false

# [client.radosgw.gateway]
# rgw init timeout = 1200
# rgw frontends = beast port=8081
# alfred@k8s:~$ 

# alfred@k8s:~$ sudo netstat -tulpen | grep -i rados
# tcp        0      0 0.0.0.0:8081            0.0.0.0:*               LISTEN      0          280412     98211/radosgw       
# tcp6       0      0 :::8081                 :::*                    LISTEN      0          280414     98211/radosgw       
# alfred@k8s:~$ 

# alfred@k8s:~$ sudo systemctl status snap.
# snap.lxd.activate.service                      snap.microceph.mgr.service                     snap.microk8s.daemon-cluster-agent.service
# snap.lxd.daemon.service                        snap.microceph.mon.service                     snap.microk8s.daemon-containerd.service
# snap.lxd.daemon.unix.socket                    snap.microceph.osd.service                     snap.microk8s.daemon-etcd.service
# snap.lxd.user-daemon.service                   snap.microceph.rbd-mirror.service              snap.microk8s.daemon-flanneld.service
# snap.lxd.user-daemon.unix.socket               snap.microceph.rgw.service                     snap.microk8s.daemon-k8s-dqlite.service
# snap.microceph.daemon.service                  snap.microk8s.daemon-apiserver-kicker.service  snap.microk8s.daemon-kubelite.service
# snap.microceph.mds.service                     snap.microk8s.daemon-apiserver-proxy.service   
# alfred@k8s:~$ sudo systemctl status snap.microceph.rgw.service 
# ● snap.microceph.rgw.service - Service for snap application microceph.rgw
#      Loaded: loaded (/etc/systemd/system/snap.microceph.rgw.service; enabled; preset: enabled)
#      Active: active (running) since Fri 2025-07-04 09:27:45 CEST; 7min ago
#    Main PID: 98211 (radosgw)
#       Tasks: 609 (limit: 19096)
#      Memory: 115.3M ()
#      CGroup: /system.slice/snap.microceph.rgw.service
#              └─98211 radosgw -f --cluster ceph --name client.radosgw.gateway -c /var/snap/microceph/1393/conf/radosgw.conf

# Jul 04 09:27:45 k8s systemd[1]: Started snap.microceph.rgw.service - Service for snap application microceph.rgw.
# Jul 04 09:28:02 k8s microceph.rgw[98211]: 2025-07-04T09:28:02.113+0200 7fde41c7c080 -1 LDAP not started since no server URIs were provided in the configuration.

# alfred@k8s:~$ sudo systemctl status snap.microceph.osd.service 
# ● snap.microceph.osd.service - Service for snap application microceph.osd
#      Loaded: loaded (/etc/systemd/system/snap.microceph.osd.service; enabled; preset: enabled)
#      Active: active (running) since Fri 2025-07-04 09:25:04 CEST; 10min ago
#    Main PID: 76065 (osd.start)
#       Tasks: 185 (limit: 19096)
#      Memory: 290.9M ()
#      CGroup: /system.slice/snap.microceph.osd.service
#              ├─76065 /bin/bash /snap/microceph/1393/commands/osd.start
#              ├─76633 ceph-osd --cluster ceph --id 1
#              ├─79993 ceph-osd --cluster ceph --id 2
#              ├─82786 ceph-osd --cluster ceph --id 3
#              └─84106 sleep infinity

# Jul 04 09:25:04 k8s systemd[1]: snap.microceph.osd.service: Scheduled restart job, restart counter is at 1.
# Jul 04 09:25:04 k8s systemd[1]: Started snap.microceph.osd.service - Service for snap application microceph.osd.
# Jul 04 09:25:09 k8s microceph.osd[76633]: 2025-07-04T09:25:09.218+0200 7b2d5e581600 -1 osd.1 0 log_to_monitors true
# Jul 04 09:25:25 k8s systemd[1]: Reloading snap.microceph.osd.service - Service for snap application microceph.osd...
# Jul 04 09:25:25 k8s systemd[1]: Reloaded snap.microceph.osd.service - Service for snap application microceph.osd.
# Jul 04 09:25:34 k8s microceph.osd[79993]: 2025-07-04T09:25:34.155+0200 7b84f100b600 -1 osd.2 0 log_to_monitors true
# Jul 04 09:25:54 k8s systemd[1]: Reloading snap.microceph.osd.service - Service for snap application microceph.osd...
# Jul 04 09:25:54 k8s systemd[1]: Reloaded snap.microceph.osd.service - Service for snap application microceph.osd.
# Jul 04 09:26:03 k8s microceph.osd[82786]: 2025-07-04T09:26:03.207+0200 7d96e2f2c600 -1 osd.3 0 log_to_monitors true
# alfred@k8s:~$ sudo systemctl status snap.microceph.mon.service 
# ● snap.microceph.mon.service - Service for snap application microceph.mon
#      Loaded: loaded (/etc/systemd/system/snap.microceph.mon.service; enabled; preset: enabled)
#      Active: active (running) since Fri 2025-07-04 09:23:29 CEST; 12min ago
#    Main PID: 68839 (ceph-mon)
#       Tasks: 25 (limit: 19096)
#      Memory: 44.5M ()
#      CGroup: /system.slice/snap.microceph.mon.service
#              └─68839 ceph-mon -f --cluster ceph --id k8s

# Jul 04 09:23:29 k8s systemd[1]: Started snap.microceph.mon.service - Service for snap application microceph.mon.
# Jul 04 09:23:34 k8s microceph.mon[68839]: 2025-07-04T09:23:34.802+0200 79e5b80c16c0 -1 mon.k8s@0(leader) e2  stashing newest monmap 2 for next startup
# alfred@k8s:~$ sudo systemctl status snap.microceph.mgr.service 
# ● snap.microceph.mgr.service - Service for snap application microceph.mgr
#      Loaded: loaded (/etc/systemd/system/snap.microceph.mgr.service; enabled; preset: enabled)
#      Active: active (running) since Fri 2025-07-04 09:23:32 CEST; 12min ago
#    Main PID: 69232 (ceph-mgr)
#       Tasks: 108 (limit: 19096)
#      Memory: 461.1M ()
#      CGroup: /system.slice/snap.microceph.mgr.service
#              └─69232 ceph-mgr -f --cluster ceph --id k8s

# Jul 04 09:30:02 k8s microceph.mgr[69232]:            ^^^^^^^^^^^^^^^^^^^^^^^^
# Jul 04 09:30:02 k8s microceph.mgr[69232]:   File "/usr/share/ceph/mgr/nfs/utils.py", line 70, in available_clusters
# Jul 04 09:30:02 k8s microceph.mgr[69232]:     completion = mgr.describe_service(service_type='nfs')
# Jul 04 09:30:02 k8s microceph.mgr[69232]:                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# Jul 04 09:30:02 k8s microceph.mgr[69232]:   File "/usr/share/ceph/mgr/orchestrator/_interface.py", line 1715, in inner
# Jul 04 09:30:02 k8s microceph.mgr[69232]:     completion = self._oremote(method_name, args, kwargs)
# Jul 04 09:30:02 k8s microceph.mgr[69232]:                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# Jul 04 09:30:02 k8s microceph.mgr[69232]:   File "/usr/share/ceph/mgr/orchestrator/_interface.py", line 1782, in _oremote
# Jul 04 09:30:02 k8s microceph.mgr[69232]:     raise NoOrchestrator()
# Jul 04 09:30:02 k8s microceph.mgr[69232]: orchestrator._interface.NoOrchestrator: No orchestrator configured (try `ceph orch set backend`)
# alfred@k8s:~$ sudo systemctl status snap.microceph.mds.service 
# ● snap.microceph.mds.service - Service for snap application microceph.mds
#      Loaded: loaded (/etc/systemd/system/snap.microceph.mds.service; enabled; preset: enabled)
#      Active: active (running) since Fri 2025-07-04 09:23:34 CEST; 13min ago
#    Main PID: 69402 (ceph-mds)
#       Tasks: 16 (limit: 19096)
#      Memory: 21.9M ()
#      CGroup: /system.slice/snap.microceph.mds.service
#              └─69402 ceph-mds -f --cluster ceph --id k8s

# Jul 04 09:23:34 k8s systemd[1]: Started snap.microceph.mds.service - Service for snap application microceph.mds.
# Jul 04 09:23:35 k8s microceph.mds[69402]: starting mds.k8s at
# alfred@k8s:~$ sudo systemctl status snap.microceph.daemon.service 
# ● snap.microceph.daemon.service - Service for snap application microceph.daemon
#      Loaded: loaded (/etc/systemd/system/snap.microceph.daemon.service; enabled; preset: enabled)
#      Active: active (running) since Fri 2025-07-04 09:24:19 CEST; 13min ago
#    Main PID: 71959 (microcephd)
#       Tasks: 17 (limit: 19096)
#      Memory: 42.2M ()
#      CGroup: /system.slice/snap.microceph.daemon.service
#              └─71959 microcephd --state-dir /var/snap/microceph/common/state

# Jul 04 09:24:19 k8s systemd[1]: Started snap.microceph.daemon.service - Service for snap application microceph.daemon.
# alfred@k8s:~$ 




# Install the Rook operator
echo "Disabling Rook..."
sudo microk8s disable rook-ceph || true

echo "Enabling Rook..."
sudo microk8s enable rook-ceph
helm ls --namespace rook-ceph
kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator"

# Wait for the Rook operator to be ready   
echo "Waiting for Rook operator to be ready..."
sudo microk8s kubectl wait --for=condition=Ready pod -l app=rook-ceph-operator --namespace rook-ceph --timeout=300s

sudo sudo microk8s helm repo add rook-release https://charts.rook.io/release
sudo sudo microk8s helm repo update

# Connect to the external Ceph cluster
echo "Connecting to external Ceph cluster..."
# This command connects the Rook operator to an existing Ceph cluster.
# It assumes that the Ceph cluster is already set up and running.
# Make sure to replace 'ceph-cluster' with the actual name of your Ceph cluster.
sudo sudo microk8s connect-external-ceph

kubectl --namespace rook-ceph-external get cephcluster

# List the storage classes in the cluster
echo "Listing storage classes..."
kubectl get storageclasses.storage.k8s.io

#echo "Patching storage classes to set ceph as default..."
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

echo "Verifying storage classes..."
sudo microk8s kubectl get storageclasses.storage.k8s.io

sudo apt install ceph-common -y
echo "Rook setup complete."

