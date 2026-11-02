#!/bin/bash
############################################################################################
#
# Generate variables for access to ceph external cluster
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition
indir="$(pwd)"

# Environments to create variable files for
ENVIRONMENTS=(k8s test)

echo "List Ceph Filesystems"
sudo microceph.ceph fs ls
echo "List Ceph Pools"
sudo microceph.ceph osd pool ls

rm -f ./create-external-cluster-resources.py*
wget -q https://raw.githubusercontent.com/rook/rook/refs/heads/release-1.18/deploy/examples/create-external-cluster-resources.py

for myenv in "${ENVIRONMENTS[@]}"; do
    echo "Creating settings for '${myenv}'"

    outfile="${indir}/vars_${myenv}.sh"
    tmpfile="${outfile}.tmp"

    sudo python3 ./create-external-cluster-resources.py \
        --ceph-conf /etc/ceph/ceph.conf \
        --keyring /etc/ceph/ceph.keyring \
        --rbd-data-pool-name "${myenv}-rbd" \
        --namespace rook-ceph \
        --cephfs-filesystem-name "${myenv}_fs" \
        --format bash > "${tmpfile}"

    test -s "${tmpfile}"
    mv "${tmpfile}" "${outfile}"
    chmod +x "${outfile}"

    echo "Created ${outfile}"
done
#