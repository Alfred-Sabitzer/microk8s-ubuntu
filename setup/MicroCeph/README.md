# MicroCeph — Configuration and Setup

This folder contains scripts and documentation to configure MicroCeph (MicroCloud-installed Ceph), enable object gateway (RGW), configure the dashboard, and integrate with Kubernetes (Rook).

## Project overview
Automates MicroCeph post-install configuration: enable RGW, create admin user, configure dashboard and metrics, and provide test pointers for Rook/Ceph integration.

## Prerequisites
- Ubuntu 22.04+ with snap support
- MicroCloud / MicroCeph installed (snap)
- microceph, ceph, radosgw-admin, netstat, curl available
- user with sudo privileges
- Cluster networking in place

## Usage
1. Make script executable:
   ```bash
   chmod +x MicroCeph.sh
   sudo ./MicroCeph.sh
   ```
2. Script prompts for a dashboard admin password unless provided via the `ADMIN_PASS` environment variable:
   ```bash
   ADMIN_PASS='secret' sudo ./MicroCeph.sh
   ```

## Configuration
- Adjust ports and targets inside `MicroCeph.sh` as needed.
- If you integrate with Kubernetes/Rook, ensure Rook is installed and storage classes point to Ceph pools.

## Testing
- Verify Ceph status:
  ```bash
  sudo microceph.ceph status
  ```
- Check RGW endpoint:
  ```bash
  curl http://$(hostname -I | awk '{print $1}'):8081
  ```

## Troubleshooting
- If RGW enable fails, inspect logs and retry after cluster reaches healthy state:
  ```bash
  sudo microceph status
  sudo journalctl -u snap.microceph.*
  ```
- Ensure required commands exist and snap services are active.

## Cleanup
- Remove temporary files created by the script are cleaned on exit. To remove RGW or dashboard, follow MicroCeph/cephadm docs.

## Security notes
- Do not store passwords in plain files or commit them to version control.
- Prefer passing `ADMIN_PASS` at runtime or use a secrets manager.
- Review generated or temporary files and remove them after use.

## References
- https://microk8s.io/docs/addon-rook-ceph
- https://canonical-microceph.readthedocs-hosted.com/en/latest/
- https://docs.ceph.com/


## links

<!--
This README provides a curated list of resources and documentation links for setting up and managing Ceph storage solutions with MicroK8s and MicroCeph. The references include official documentation, tutorials, and community guides covering installation, configuration, and integration of Ceph and Rook within Kubernetes environments. Use these links to explore step-by-step guides, best practices, and advanced topics related to Ceph storage clusters, MicroCeph, and Rook operator deployment.
-->
https://microk8s.io/docs/addon-rook-ceph
https://github.com/rook/rook
https://rook.io/docs/rook/latest-release/Getting-Started/intro/
https://rook.io/docs/rook/latest-release/Getting-Started/quickstart/#deploy-the-rook-operator
https://microk8s.io/docs/how-to-ceph
https://docs.ceph.com/en/reef/
https://canonical-microceph.readthedocs-hosted.com/en/latest/tutorial/get-started/
https://www.howtoforge.de/anleitung/wie-man-einen-ceph-storage-cluster-unter-ubuntu-1604-installiert/
https://www.digitalocean.com/community/tutorials/how-to-set-up-a-ceph-cluster-within-kubernetes-using-rook
https://ubuntu.com/ceph/install
https://www.thomas-krenn.com/de/wiki/Ceph
https://canonical-microceph.readthedocs-hosted.com/_/downloads/en/latest/pdf/?utm_source=canonical-microceph&utm_content=flyout
https://docs.ceph.com/en/squid/radosgw/vault/
https://www.cloudthat.com/resources/blog/streamlining-ceph-cluster-management-with-microceph-an-ultimate-guide
https://canonical-microceph.readthedocs-hosted.com/en/latest/how-to/mount-block-device/
https://github.com/cloudlena/s3manager
https://discuss.kubernetes.io/t/microk8s-microceph-cephfs-ubuntu-22/29022


