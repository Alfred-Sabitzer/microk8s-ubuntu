# Cluster Setup

This is a documentation of all necessary steps to initialy setup a microk8s cluster.
This configuration has to be done the same way on all participation Nodes.

# Preconditions

It is necessary to change some configurations on every participating node.

## Working Ubuntu LTS

Please consider https://microk8s.io/docs and https://ubuntu.com/tutorials/install-a-local-kubernetes-with-microk8s#1-overview

## Configuration of cgroups

```bash
$ stat -fc %T /sys/fs/cgroup/
tmpfs
```

This command checks, which version of cgroups is active.

Change startup-command for for grub

`GRUB_CMDLINE_LINUX=" net.ifnames=0 video=1024x768"`

in /etc/default/grub to

`GRUB_CMDLINE_LINUX=" net.ifnames=0 video=1024x768 cgroup_enable=memory cgroup_memory=1 swapaccount=1 systemd.unified_cgroup_hierarchy=0"`

then update your grub and restart the node.

```bash
sudo update-grub
sudo shutdown -r now
```

After this croups are configured.

## Enabling Swap-File

Swap-file is a little bit scary. In prinipe K8S is managing this by himself. For the case you have a small raspberry running, you can give this a try.
Dont do this in real productive environments.

```bash
dd if=/dev/zero of=/swapfile.img bs=1024 count=3M
mkswap /swapfile.img
chmod 0600 /swapfile.img
nano /etc/fstab # Eintragen von /swapfile.img swap swap sw 0 0
swapon /swapfile.img
cat /proc/swaps
grep 'Swap' /proc/meminfo
shutdown -r now
cat /proc/swaps
grep Swap /proc/meminfo
sudo dmesg
```

## Visudo-Eintrag:

This visudo-entries are for more comfort when acting on the system.

```bash
# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) NOPASSWD:ALL
```

Now you have to add a user (eg. ansible) to this group.
In our example we use user slainte for this.

```bash
adduser slainte
usermod -aG sudo slainte
```
Example:

```bash
root@v22022112011208453:~# adduser slainte
Adding user `slainte' ...
Adding new group `slainte' (1001) ...
Adding new user `slainte' (1001) with group `slainte' ...
Creating home directory `/home/slainte' ...
Copying files from `/etc/skel' ...
New password:
Retype new password:
passwd: password updated successfully
Changing the user information for slainte
Enter the new value, or press ENTER for the default
Full Name []: Slainte User
Room Number []:
Work Phone []:
Home Phone []:
Other []:
Is the information correct? [Y/n] Y
root@v22022112011208453:~# usermod -aG sudo slainte
```
lets change to User Slainte

```bash
root@v22022112011208453:~# su -l slainte
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.
slainte@v22022112011208453:~$ whoami
slainte
```
# Configuration sshd

```bash
nano /etc/ssh/sshd_config


# Authentication:

LoginGraceTime 2m
StrictModes yes
MaxAuthTries 6
MaxSessions 10

PubkeyAuthentication yes

PasswordAuthentication no
PermitRootLogin no

AllowUsers slainte 
```

This entries are for security,so that only allowd accounts can log on.


# Installation

Execute the prepared [Setup.sh](Setup.sh)

```bash
slainte@v22022112011208453:~$ ./Setup.sh
```
**This has to be done on every single node.**

Consider https://discuss.kubernetes.io/t/dockerhub-download-rate-limits/18729
You need to configure the correct external repositories for your nodes.

# Docker Repositories

For proper work, you will need several trusted internal and external repositories.
Configuration and setup is done in [MicroK8S_Docker.sh](MicroK8S_Install/MicroK8S_Docker.sh)
Please configure this script according to your needs.

# Number of Pods per Node

If you habe tiny nodes (eg. raspberries) then you can try to incrase the number of allowed pods per node.

Lets increase the standard from 110 pods to 234 (its just a beautiful number).
Please consider https://blog.kubovy.eu/2020/05/16/the-kubernetes-110-pod-limit-per-node/

```bash
cat /var/snap/microk8s/current/args/kubelet
--cluster-dns=10.152.183.10
--cluster-domain=cluster.local
--kubeconfig=${SNAP_DATA}/credentials/kubelet.config
--cert-dir=${SNAP_DATA}/certs
--client-ca-file=${SNAP_DATA}/certs/ca.crt
--anonymous-auth=false
--root-dir=${SNAP_COMMON}/var/lib/kubelet
--log-dir=${SNAP_COMMON}/var/log
--fail-swap-on=false
--feature-gates=DevicePlugins=true
--eviction-hard="memory.available<100Mi,nodefs.available<1Gi,imagefs.available<1Gi"
--container-runtime=remote
--container-runtime-endpoint=${SNAP_COMMON}/run/containerd.sock
--containerd=${SNAP_COMMON}/run/containerd.sock
--node-labels="microk8s.io/cluster=true,node.kubernetes.io/microk8s-controlplane=microk8s-controlplane"
--authentication-token-webhook=true
--read-only-port=0
--max-pods=234

microk8s stop
microk8s start
```

Lets check

```bash
kubectl get nodes -o yaml
apiVersion: v1
items:
- apiVersion: v1
  kind: Node
  metadata:
    annotations:
      node.alpha.kubernetes.io/ttl: "0"
      projectcalico.org/IPv4Address: 192.168.178.36/24
      projectcalico.org/IPv4VXLANTunnelAddr: 10.1.77.0
      volumes.kubernetes.io/controller-managed-attach-detach: "true"
    creationTimestamp: "2025-05-26T16:09:28Z"
    labels:
      beta.kubernetes.io/arch: amd64
      beta.kubernetes.io/os: linux
      kubernetes.io/arch: amd64
      kubernetes.io/hostname: k8s
      kubernetes.io/os: linux
      microk8s.io/cluster: "true"
      node.kubernetes.io/microk8s-controlplane: microk8s-controlplane
    name: k8s
    resourceVersion: "1588"
    uid: 1f33acbb-8a7f-4947-9e1f-a53b0f8e0578
  spec: {}
  status:
    addresses:
    - address: 192.168.178.36
      type: InternalIP
    - address: k8s
      type: Hostname
    allocatable:
      cpu: "6"
      ephemeral-storage: 48304944Ki
      hugepages-2Mi: "0"
      memory: 16274108Ki
      pods: "234"
    capacity:
      cpu: "6"
      ephemeral-storage: 49353520Ki
      hugepages-2Mi: "0"
      memory: 16376508Ki
      pods: "234"
    conditions:
    - lastHeartbeatTime: "2025-05-26T18:22:25Z"
      lastTransitionTime: "2025-05-26T18:22:25Z"
      message: Calico is running on this node
      reason: CalicoIsUp
      status: "False"
      type: NetworkUnavailable
    - lastHeartbeatTime: "2025-05-26T18:22:18Z"
      lastTransitionTime: "2025-05-26T16:09:28Z"
      message: kubelet has sufficient memory available
      reason: KubeletHasSufficientMemory
      status: "False"
      type: MemoryPressure
    - lastHeartbeatTime: "2025-05-26T18:22:18Z"
      lastTransitionTime: "2025-05-26T16:09:28Z"
      message: kubelet has no disk pressure
      reason: KubeletHasNoDiskPressure
      status: "False"
      type: DiskPressure
    - lastHeartbeatTime: "2025-05-26T18:22:18Z"
      lastTransitionTime: "2025-05-26T16:09:28Z"
      message: kubelet has sufficient PID available
      reason: KubeletHasSufficientPID
      status: "False"
      type: PIDPressure
    - lastHeartbeatTime: "2025-05-26T18:22:18Z"
      lastTransitionTime: "2025-05-26T16:09:47Z"
      message: kubelet is posting ready status
      reason: KubeletReady
      status: "True"
      type: Ready
    daemonEndpoints:
      kubeletEndpoint:
        Port: 10250
    images:
    - names:
      - docker.io/calico/node@sha256:d8c644a8a3eee06d88825b9a9fec6e7cd3b7c276d7f90afa8685a79fb300e7e3
      - docker.io/calico/node:v3.28.1
      sizeBytes: 117874046
    - names:
      - docker.io/calico/cni@sha256:e486870cfde8189f9ea145148bc353a2c0fca1f445213274023c1d11df69ae19
      - docker.io/calico/cni:v3.28.1
      sizeBytes: 94576755
    - names:
      - docker.io/calico/kube-controllers@sha256:eadb3a25109a5371b7b2dc30d74b2d9b2083eba58abdc034c81f974a48871330
      - docker.io/calico/kube-controllers:v3.28.1
      sizeBytes: 35000112
    - names:
      - docker.io/coredns/coredns@sha256:a0ead06651cf580044aeb0a0feba63591858fb2e43ade8c9dea45a6a89ae7e5e
      - docker.io/coredns/coredns:1.10.1
      sizeBytes: 16190758
    - names:
      - registry.k8s.io/pause@sha256:ee6521f290b2168b6e0935a181d4cff9be1ac3f505666ef0e3c98fae8199917a
      - registry.k8s.io/pause:3.10
      sizeBytes: 320368
    nodeInfo:
      architecture: amd64
      bootID: 584bf4bf-5270-4923-9020-10595aca5484
      containerRuntimeVersion: containerd://1.6.36
      kernelVersion: 6.8.0-60-generic
      kubeProxyVersion: v1.32.3
      kubeletVersion: v1.32.3
      machineID: 13b28e63462b497cad4cee2de9d91eef
      operatingSystem: linux
      osImage: Ubuntu 24.04.2 LTS
      systemUUID: 88a4f48a-a7db-0b4c-a9f4-8feaeda2209a
kind: List
metadata:
  resourceVersion: ""
```
And now we enabled more pods than usual.

**Dont do this in real productive environments.**
