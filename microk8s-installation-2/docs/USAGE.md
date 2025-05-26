# Usage Instructions for MicroK8s Installation Scripts

This document provides usage instructions for the MicroK8s installation scripts included in this project. Follow the steps below to successfully install and configure MicroK8s on your system.

## Prerequisites

Before running the installation scripts, ensure that you have the following:

- A compatible version of Ubuntu installed on your machine.
- Administrative (sudo) access to your system.
- Snap package manager installed (usually pre-installed on Ubuntu).

## Installation Scripts

### 1. MicroK8S_Install.sh

This script installs MicroK8s using the snap package manager.

#### Usage

To run the installation script, execute the following command in your terminal:

```bash
sudo bash scripts/MicroK8S_Install.sh
```

#### What it does

- Installs MicroK8s from the snap store.
- Checks the return code of the installation command and retries if it fails.
- Sets up aliases for `kubectl` to simplify command usage.
- Runs a startup script to ensure MicroK8s is ready for use.

### 2. MicroK8S_Docker.sh

This script configures Docker repositories for MicroK8s.

#### Usage

To configure Docker repositories, run:

```bash
sudo bash scripts/MicroK8S_Docker.sh
```

#### What it does

- Creates directories for trusted Docker repositories.
- Writes configuration files for each specified repository.

### 3. MicroK8S_ufw.sh

This script configures the UFW firewall for MicroK8s.

#### Usage

To set up the firewall, execute:

```bash
sudo bash scripts/MicroK8S_ufw.sh
```

#### What it does

- Resets the UFW firewall settings.
- Allows necessary traffic for pod-to-pod and pod-to-internet communication.
- Enables the firewall with specific rules for OpenSSH and Nginx.

## Conclusion

After running the above scripts, MicroK8s should be installed and configured on your system. You can verify the installation by running:

```bash
microk8s status --wait-ready
```

For further assistance, refer to the README.md file or the official MicroK8s documentation.