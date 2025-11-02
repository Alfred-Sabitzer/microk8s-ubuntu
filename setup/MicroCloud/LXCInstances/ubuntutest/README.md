# demo standard

Create a test-instance. This instance is for connectivity testing.


## Instance Generator Usage

To generate an LXD instance configuration file and start script from a template, run:


````bash
./demostandard_instancegenerator.sh
````

## Security Notes

- Do not store sensitive data (e.g., SSH keys, passwords) in templates or generated files.
- Review generated files before deployment.
- Never commit secrets to version control.

## References
- [Instance Generator](https://github.com/Alfred-Sabitzer/microk8s-ubuntu/tree/main/setup/MicroCloud/InstanceGenerator)
- [MicroCloud Documentation](https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/)
- [Snap Documentation](https://snapcraft.io/docs)
- [Cloud Init Documentation](https://cloudinit.readthedocs.io/en/latest/reference/modules.html)
- [Microcloud working Example](https://documentation.ubuntu.com/microcloud/latest/microcloud/tutorial/get_started/)
- [Alternative working Example](https://cloudbricks.dev/post/cloud/canonical/microcloud/)
- [Possible Configuration Traps](https://github.com/canonical/microcloud/issues/210)
- [Podman Setup](https://linuxconfig.org/getting-started-with-containers-via-podman-no-docker-daemon-required)
