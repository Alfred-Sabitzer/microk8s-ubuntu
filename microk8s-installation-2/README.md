# MicroK8s Installation Project

This project provides a set of scripts for installing and configuring MicroK8s, a lightweight Kubernetes distribution. The scripts automate the installation process, configure Docker repositories, and set up firewall rules to ensure a smooth operation of MicroK8s.

## Overview

MicroK8s is a minimal, lightweight Kubernetes distribution designed for developers and DevOps. This project includes scripts that simplify the installation and configuration of MicroK8s on Ubuntu systems.

## Scripts

### 1. `MicroK8S_Install.sh`
This script installs MicroK8s using the snap package manager. It checks the return code of the installation command and retries if it fails. Additionally, it sets up aliases for `kubectl` and runs a startup script to ensure MicroK8s is ready for use.

### 2. `MicroK8S_Docker.sh`
This script configures Docker repositories for MicroK8s. It creates necessary directories for trusted Docker repositories and writes configuration files for each repository, allowing MicroK8s to pull images from these repositories.

### 3. `MicroK8S_ufw.sh`
This script configures the UFW (Uncomplicated Firewall) for MicroK8s. It resets the firewall, allows necessary traffic for pod-to-pod and pod-to-internet communication, and enables the firewall with specific rules for OpenSSH and Nginx.

## Usage

For detailed usage instructions, please refer to the [USAGE.md](docs/USAGE.md) file, which provides step-by-step guidance on how to run each script and any prerequisites needed for successful execution.

## License

This project is licensed under the terms specified in the LICENSE file. Please review the LICENSE file for more information on how the code can be used and distributed.

## Additional Information

For any issues or contributions, please refer to the project's repository or contact the maintainers. Your feedback and contributions are welcome!