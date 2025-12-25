# Istio on MicroK8s — Setup, Validation and Demo

This is a collection of various task based on bookinfo.
All examples are done in namespace bookinfo.
Example code is from istio.

````bash
export NAMESPACE="bookinfo"
export istio_dir="/opt/istio-installation/istio-1.28.1"
````
**We will consequently use the istio-api. The Kubernetes api does still not provide all neede features regarding security**

## Purpose

Evaluate all examples from https://istio.io/latest/docs/overview/

## References
- [Istio docs:](https://istio.io/latest/docs/)
- [Istio Installation prerequistes:](https://istio.io/latest/docs/ambient/install/platform-prerequisites/)
- [Install Istio with helm](https://istio.io/latest/docs/setup/install/helm/)
- [Ambient Installation with helm](https://ambientmesh.io/docs/setup/installation/)
- [Why Does Istio Ambient Mode Enforce mTLS?](https://jimmysong.io/blog/why-ambient-mode-enforced-mtls/)
- [Install all Istio-components with helm](https://artifacthub.io/packages/helm/code4devs/istio-all)
- [ISTIO MTLS Example:](https://medium.com/microsoftazure/certificate-pinning-for-mtls-authentication-at-the-istio-ingress-gateway-978ed31699ab)
- [istioctl analyze:](https://istio.io/latest/docs/ops/diagnostic-tools/istioctl-analyze/)
- [Deploy Istio](https://gist.github.com/Realiserad/391855c4a0fb0072994e5ad2a53d65c0)
- [MicroK8s Istio addon::]( https://microk8s.io/docs/addon-istio)
- [Prometheus Operator:](https://github.com/prometheus-operator/prometheus-operator)
- [cert-manager:](https://cert-manager.io/docs/)

## License / Notes

These scripts and manifests are provided for testing and demo usage. Review and adapt for production.