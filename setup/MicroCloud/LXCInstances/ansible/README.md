# ansible

Deployment of ansiblibe master node. This node can reach all the others via ansible.


## Instance Generator Usage

To generate an LXD instance configuration file and start script from a template, run:

````bash
./ansible_instancegenerator.sh
````

## Security Notes

- Do not store sensitive data (e.g., SSH keys, passwords) in templates or generated files.
- Review generated files before deployment.
- Never commit secrets to version control.

## References
- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Getting startd](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- [Instance Generator](https://github.com/Alfred-Sabitzer/microk8s-ubuntu/tree/main/setup/MicroCloud/InstanceGenerator)
- [MicroCloud Documentation](https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/)
- [Snap Documentation](https://snapcraft.io/docs)
- [Cloud Init Documentation](https://cloudinit.readthedocs.io/en/latest/reference/modules.html)
- [Microcloud working Example](https://documentation.ubuntu.com/microcloud/latest/microcloud/tutorial/get_started/)
- [Alternative working Example](https://cloudbricks.dev/post/cloud/canonical/microcloud/)
- [Possible Configuration Traps](https://github.com/canonical/microcloud/issues/210)

