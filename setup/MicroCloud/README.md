# MicroCloud Cluster Installation

## Project Overview
Automates installation of MicroCloud, LXD, MicroCeph, and MicroOVN on all cluster nodes using Ansible and Snap.

## Prerequisites
- Ubuntu 22.04+ on all nodes
- Passwordless sudo for the user running scripts
- Ansible installed and configured
- snapd installed on all nodes

## Usage

```bash
chmod +x MicroCloud_Install_all_nodes.sh
./MicroCloud_Install_all_nodes.sh
```

## Configuration
- Adjust Ansible inventory to match your node hostnames/IPs.
- Edit snap channels in the script if you need different versions.

## Testing
- Check snap status: `snap list`
- Verify services: `systemctl status snap.microcloud.*` on each node

## Troubleshooting
- Check Ansible output for errors.
- Ensure SSH connectivity and sudo permissions.
- Check snap logs: `journalctl -u snapd`

## Cleanup
- Remove snaps: `sudo snap remove microcloud microceph microovn lxd` on all nodes.

## References
- [MicroCloud Documentation](https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/)
- [Snap Documentation](https://snapcraft.io/docs)
- [Cloud Init Documentation](https://cloudinit.readthedocs.io/en/latest/reference/modules.html)
- [Microcloud working Example](https://documentation.ubuntu.com/microcloud/latest/microcloud/tutorial/get_started/)


## Security Notes
- Ensure SSH keys and sudo access are managed securely.
- Review disk encryption configuration for compliance with your security policies.
