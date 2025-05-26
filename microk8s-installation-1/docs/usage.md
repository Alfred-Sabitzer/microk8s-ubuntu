# Usage Instructions for MicroK8s Installation Scripts

This document provides detailed usage instructions for the MicroK8s installation scripts included in the `microk8s-installation` project. Follow the steps below to successfully install and configure MicroK8s on your system.

## Prerequisites

Before running the installation scripts, ensure that you have the following:

- A compatible version of Ubuntu installed on your machine.
- Administrative (sudo) access to your system.
- Snap package manager installed (usually pre-installed on Ubuntu).

## Installation Steps

### 1. Install MicroK8s

To install MicroK8s, run the following script:

```bash
bash scripts/MicroK8S_Install.sh
```

This script will:
- Install MicroK8s using the snap package manager.
- Check for successful installation and set up aliases for `kubectl`.
- Call the `MicroK8S_Start.sh` script to start MicroK8s.
- Log the inspection results to `microk8s_inspect.log`.

### 2. Configure Docker Repositories

If you need to configure Docker repositories for MicroK8s, execute the following script:

```bash
bash scripts/MicroK8S_Docker.sh
```

This script will:
- Create necessary directories for Docker certificates.
- Set up trusted Docker repositories by writing configuration files.

### 3. Configure UFW Firewall

To configure the UFW firewall for MicroK8s, run:

```bash
bash scripts/MicroK8S_ufw.sh
```

This script will:
- Reset the UFW firewall.
- Allow necessary traffic for pod-to-pod and pod-to-internet communication.
- Enable the firewall with specific rules for OpenSSH and Nginx.

## Additional Information

- Ensure that you have the required permissions to execute these scripts.
- Review the output of each script for any errors or warnings.
- For further assistance, refer to the README.md file or the official MicroK8s documentation.

By following these instructions, you should be able to successfully install and configure MicroK8s on your Ubuntu system.