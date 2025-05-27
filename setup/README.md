# Setup MicroK8S

Please note, that some preconfiguration requirements are necessary.
Please read as well the other readme's and try to understand, what these scripts are doing for you.

Please note, that this is not intended for serious production environments.
This is only a case-study for private home-use.

Please consider https://microk8s.io/docs and https://ubuntu.com/tutorials/install-a-local-kubernetes-with-microk8s#1-overview

# First Step

This step has to be done on all participating Nodes (so that all nodes habe a proper installation and donfiguration).

Read CAREFULLY [README_PreInstallation.md](README_PreInstallation.md)

Then execute [Setup.sh](Setup.sh)

After successful Installation K8S in Standard-Mode is waiting for you

# Second Step

Follow Instruction of [SetupMicroK8S.sh](SetupMicroK8S.sh)


# MicroK8S Start/Stop Scripts

Scripts to reliably start and stop MicroK8s with retry logic.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed
- User in the `microk8s` group or `sudo` privileges

## Usage

```bash
chmod +x MicroK8S_Start.sh MicroK8S_Stop.sh
./MicroK8S_Start.sh   # To start MicroK8s
./MicroK8S_Stop.sh    # To stop MicroK8s
```

## Notes

- The scripts will retry up to 10 times if MicroK8s fails to start or stop.
- If you encounter permission errors, try running the scripts with `sudo`.

## Troubleshooting

- Ensure your user is in the `microk8s` group:  
  `sudo usermod -a -G microk8s $USER && newgrp microk8s`
- Check MicroK8s status:  
  `microk8s status`
