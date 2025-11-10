# Kubernetes Engine - k8stest

Master Template for the kubernetes server - Testinstance


## Instance Generator Usage

To generate an LXD instance configuration file and start script from a template, run:

````bash
./instancegenerator.sh
````

Software-snaps and proper sizings for memory etc. has to be done interactively.
Dont forget for hardenings!

## Security Notes

- Do not store sensitive data (e.g., SSH keys, passwords) in templates or generated files.
- Review generated files before deployment.
- Never commit secrets to version control.

## References

- [OpenVPN Community](https://openvpn.net/community/)
- [OpenVPN Install](https://documentation.ubuntu.com/server/how-to/security/install-openvpn/)
- [App Armor](https://documentation.ubuntu.com/server/how-to/security/apparmor/)
- [Ubuntu Security](https://documentation.ubuntu.com/server/how-to/security/)
- [MicroCloud Documentation](https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/)
- [Snap Documentation](https://snapcraft.io/docs)
- [Cloud Init Documentation](https://cloudinit.readthedocs.io/en/latest/reference/modules.html)
- [Microcloud working Example](https://documentation.ubuntu.com/microcloud/latest/microcloud/tutorial/get_started/)
- [Alternative working Example](https://cloudbricks.dev/post/cloud/canonical/microcloud/)
- [Possible Configuration Traps](https://github.com/canonical/microcloud/issues/210)

