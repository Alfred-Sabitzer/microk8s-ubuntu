# MicroCeph + RookCeph + OpenBao Integration

This setup demonstrates how to use MicroCeph with encrypted disks, managed by secrets in OpenBao, and integrates with RookCeph for Kubernetes storage.

## Prerequisites

- Ubuntu 22.04+ with snap support
- [MicroK8s](https://microk8s.io/) and [MicroCeph](https://ubuntu.com/ceph/install)
- User in the `microk8s` and `sudo` groups
- `dmsetup`, `s3cmd`, `radosgw-admin` installed

## Quick Start

1. Install and configure MicroCeph:
    ```bash
    chmod +x MicroK8SRookCeph.sh
    ./MicroK8SRookCeph.sh
    ```

2. Configure OpenBao for MicroCeph:
    ```bash
    chmod +x MicroCeph_openBao_setup.sh
    ./MicroCeph_openBao_setup.sh
    ```

## Configuration

- Edit device names and storage classes in scripts and YAML as needed for your environment.
- Adjust namespace and resource names to avoid conflicts.

## Testing

- Use the provided `test/busybox.yaml` to verify PVC provisioning and encryption.
- Use `s3cmd` to test S3 access and encryption.
- Check Ceph status:
  ```bash
  sudo microk8s kubectl get pods -n rook-ceph
  sudo microk8s kubectl get pvc,pv
  ```
- Test S3 access:
  ```bash
  s3cmd ls s3://your-bucket
  ```

## Troubleshooting

- If pods are stuck in Pending, check storage class and Ceph status.
- For permission errors, ensure your user is in the `microk8s` and `sudo` groups.
- Check logs:
  ```bash
  sudo microk8s kubectl logs <pod-name> -n rook-ceph
  ```

## Cleanup

- Remove test resources:
  ```bash
  sudo microk8s kubectl delete -f test/busybox.yaml
  ```
- Uninstall Ceph and related snaps as needed.

## Security Notes

- **Never store root tokens or unseal keys in plain files or ConfigMaps in production.**
- Review all scripts and YAML for sensitive data before use in production.

## References

- [MicroCeph Docs](https://canonical-microceph.readthedocs-hosted.com/en/latest/)
- [Ceph Docs](https://docs.ceph.com/en/quincy/mgr/dashboard/)
- [RookCeph Docs](https://rook.io/docs/)
- [OpenBao Docs](https://openbao.org/docs/)

## links

<!--
This README provides a curated list of resources and documentation links for setting up and managing Ceph storage solutions with sudo microk8s and MicroCeph. The references include official documentation, tutorials, and community guides covering installation, configuration, and integration of Ceph and Rook within Kubernetes environments. Use these links to explore step-by-step guides, best practices, and advanced topics related to Ceph storage clusters, MicroCeph, and Rook operator deployment.
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


