# Ceph Cluster Automation

## Project Overview
Automates installation, configuration, and removal of a Ceph cluster using Ansible scripts and playbooks.

## Prerequisites
- Ubuntu 22.04+ on all nodes
- Passwordless sudo for the user running scripts
- Ansible installed and configured
- SSH keys distributed to all nodes

## Usage

### Install Ceph
```bash
chmod +x Ceph_Install.sh
./Ceph_Install.sh
```

### Distribute SSH Keys
```bash
chmod +x copy_id_pub.sh
./copy_id_pub.sh
```

### Remove Ceph
```bash
chmod +x Ceph_delete.sh
./Ceph_delete.sh
```

## Configuration
- Adjust inventory and hostnames in Ansible as needed.
- Edit playbooks to match your environment.

## Testing
- Check Ceph status: `sudo ceph status`
- Verify services: `systemctl status ceph*`

## Troubleshooting
- Check Ansible output for errors.
- Ensure SSH connectivity between nodes.
- Verify sudo permissions.

## Cleanup
- Use `Ceph_delete.sh` to remove all Ceph components and data.

## References
- [Ceph Installation Guide](https://docs.ceph.com/en/latest/cephadm/install/)
- [MicroCeph Documentation](https://canonical-microceph.readthedocs-hosted.com/en/squid-stable/)

## Security Notes
- Do not store sensitive keys or passwords in scripts or playbooks.
- Ensure SSH keys are distributed securely.

