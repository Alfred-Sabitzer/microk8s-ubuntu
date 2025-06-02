#!/bin/bash
############################################################################################
#
# Mount CephFS with MicroCeph
#
# https://canonical-microceph.readthedocs-hosted.com/en/reef-stable/tutorial/mount-block-device/
# https://canonical-microceph.readthedocs-hosted.com/en/reef-stable/tutorial/mount-cephfs-share/
# https://askubuntu.com/questions/1486768/how-to-mount-ceph-fs-with-microceph
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

setup/MicroK8SStorage/RookCeph/MicroCeph_Rados.sh