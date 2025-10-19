# MicroCeph — Configuration and Setup

This folder contains scripts and documentation to configure MicroCeph (MicroCloud-installed Ceph), enable object gateway (RGW), configure the dashboard, and integrate with Kubernetes (Rook).

## Project overview
Automates MicroCeph post-install configuration: create pools, enable RGW, create admin user, configure dashboard and metrics, and provide test pointers for Rook/Ceph integration.

## Prerequisites
- Ubuntu 22.04+ with snap support
- MicroCloud / MicroCeph installed (snap)
- `microceph`, `ceph`, `radosgw-admin`, `lxc` (LXD), `curl` available on host
- user with sudo privileges
- Cluster networking in place

## Scripts
- `MicroCeph.sh` — post-install configuration (RGW, dashboard, telemetry).
- `MicroCeph_Pool.sh` — idempotent creation of Ceph pools, CephFS and LXD storage entries.

## Usage
1. Make scripts executable:
   ```bash
   chmod +x MicroCeph.sh MicroCeph_Pool.sh
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

## References
- [MikroK8S addon rook](https://microk8s.io/docs/addon-rook-ceph)
- [MicroCeph Documentation](https://canonical-microceph.readthedocs-hosted.com/en/latest/)
- [ceph Documentation](https://docs.ceph.com/)
- [Rook Documentation](https://github.com/rook/rook)
- [Rook getting started](https://rook.io/docs/rook/latest-release/Getting-Started/intro/)
- [Rook Operator](https://rook.io/docs/rook/latest-release/Getting-Started/quickstart/#deploy-the-rook-operator)
- [How to ceph](https://microk8s.io/docs/how-to-ceph)
   
