#!/bin/bash
############################################################################################
#
# Generate variables for access to ceph external cluster
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition
indir="$(pwd)"

# Environments to create variable files for
ENVIRONMENTS=(k8s test)

echo "List Ceph Filesystems"
sudo microceph.ceph fs ls
echo "List Ceph Pools"
sudo microceph.ceph osd pool ls

# Create settings
for myenv in "${ENVIRONMENTS[@]}"; do
echo "Creating Setting for '${myenv}'"
    echo "sudo python3  ./create-external-cluster-resources.py --rbd-data-pool-name ${myenv}-rbd --namespace rook-ceph --cephfs-filesystem-name ${myenv}_fs --format bash > ${indir}/vars_${myenv}.sh"
    sudo python3 ./create-external-cluster-resources.py --rbd-data-pool-name ${myenv}-rbd --namespace rook-ceph --cephfs-filesystem-name ${myenv}_fs --format bash > ${indir}/vars_${myenv}.sh
done
cd ${indir}
echo "Completed generating variable files in ${indir}"
echo "Files: vars_k8s.sh , vars_test.sh"
chmod +x ${indir}/vars_*.sh
echo "Files made executable"
#