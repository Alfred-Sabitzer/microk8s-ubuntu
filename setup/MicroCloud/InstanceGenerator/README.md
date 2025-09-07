# LXD Instance Generator

## Project Overview
Aim is to generate instamce configuration Files including start script baes on templates.

## Prerequisites:

- Python 3.x
- Template files in the specified template directory
- Write permissions in the output directory

## Instance Generator Usage


To generate an LXD instance configuration file and start script from a template, run:


````bash
python instancegenerator.py --project=<LXD project> --profile=<LXD profile> --image=<LXD Image Name> --type=<minimal or full or ..> --template_dir=<template directory> --name=<instance name>
````

- Adjust variables in the template or pass them as arguments.
- Validate generated YAML with:

````bash
cloud-init devel schema --config ./demo.yaml
````

## Security Notes

- Do not store sensitive data (e.g., SSH keys, passwords) in templates or generated files.
- Review generated files before deployment.
- Never commit secrets to version control.

## References
- [MicroCloud Documentation](https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/)
- [Snap Documentation](https://snapcraft.io/docs)
- [Cloud Init Documentation](https://cloudinit.readthedocs.io/en/latest/reference/modules.html)
- [Microcloud working Example](https://documentation.ubuntu.com/microcloud/latest/microcloud/tutorial/get_started/)
- [Alternative working Example](https://cloudbricks.dev/post/cloud/canonical/microcloud/)
- [Possible Configuration Traps](https://github.com/canonical/microcloud/issues/210)
- [Podman Setup](https://linuxconfig.org/getting-started-with-containers-via-podman-no-docker-daemon-required)
