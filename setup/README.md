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

```bash
+ sudo microk8s status --wait-ready
microk8s is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
addons:
  enabled:
    dashboard-ingress    # (community) Ingress definition for Kubernetes dashboard
    openebs              # (community) OpenEBS is the open-source storage solution for Kubernetes
    cert-manager         # (core) Cloud native certificate management
    community            # (core) The community addons repository
    dashboard            # (core) The Kubernetes dashboard
    dns                  # (core) CoreDNS
    ha-cluster           # (core) Configure high availability on the current node
    helm                 # (core) Helm - the package manager for Kubernetes
    helm3                # (core) Helm 3 - the package manager for Kubernetes
    hostpath-storage     # (core) Storage class; allocates storage from host directory
    ingress              # (core) Ingress controller for external access
    metrics-server       # (core) K8s Metrics Server for API access to service metrics
    rbac                 # (core) Role-Based Access Control for authorisation
    registry             # (core) Private image registry exposed on localhost:32000
    storage              # (core) Alias to hostpath-storage add-on, deprecated
  disabled:
    argocd               # (community) Argo CD is a declarative continuous deployment for Kubernetes.
    cilium               # (community) SDN, fast with full network policy
    cloudnative-pg       # (community) PostgreSQL operator CloudNativePG
    easyhaproxy          # (community) EasyHAProxy can configure HAProxy automatically based on ingress labels
    falco                # (community) Cloud-native runtime threat detection tool for Linux and K8s
    fluentd              # (community) Elasticsearch-Fluentd-Kibana logging and monitoring
    gopaddle             # (community) DevSecOps and Multi-Cloud Kubernetes Platform
    inaccel              # (community) Simplifying FPGA management in Kubernetes
    istio                # (community) Core Istio service mesh services
    jaeger               # (community) Kubernetes Jaeger operator with its simple config
    kata                 # (community) Kata Containers is a secure runtime with lightweight VMS
    keda                 # (community) Kubernetes-based Event Driven Autoscaling
    knative              # (community) Knative Serverless and Event Driven Applications
    kubearmor            # (community) Cloud-native runtime security enforcement system for k8s
    kwasm                # (community) WebAssembly support for WasmEdge (Docker Wasm) and Spin (Azure AKS WASI)
    linkerd              # (community) Linkerd is a service mesh for Kubernetes and other frameworks
    microcks             # (community) Open source Kubernetes Native tool for API Mocking and Testing
    multus               # (community) Multus CNI enables attaching multiple network interfaces to pods
    nfs                  # (community) NFS Server Provisioner
    ngrok                # (community) ngrok Ingress Controller instantly adds connectivity, load balancing, authentication, and observability to your services
    openfaas             # (community) OpenFaaS serverless framework
    osm-edge             # (community) osm-edge is a lightweight SMI compatible service mesh for the edge-computing.
    parking              # (community) Static webserver to park a domain. Works with EasyHAProxy.
    portainer            # (community) Portainer UI for your Kubernetes cluster
    shifu                # (community) Kubernetes native IoT software development framework.
    sosivio              # (community) Kubernetes Predictive Troubleshooting, Observability, and Resource Optimization
    traefik              # (community) traefik Ingress controller
    trivy                # (community) Kubernetes-native security scanner
    cis-hardening        # (core) Apply CIS K8s hardening
    gpu                  # (core) Alias to nvidia add-on
    host-access          # (core) Allow Pods connecting to Host services smoothly
    kube-ovn             # (core) An advanced network fabric for Kubernetes
    mayastor             # (core) OpenEBS MayaStor
    metallb              # (core) Loadbalancer for your Kubernetes cluster
    minio                # (core) MinIO object storage
    nvidia               # (core) NVIDIA hardware (GPU and network) support
    observability        # (core) A lightweight observability stack for logs, traces and metrics
    prometheus           # (core) Prometheus operator for monitoring and logging
    rook-ceph            # (core) Distributed Ceph storage using Rook
```
# Second Step

Follow Instruction of [SetupMicroK8S.sh](SetupMicroK8S.sh)
