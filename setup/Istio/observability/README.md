# Istio on MicroK8s — Observability

This folder contains helpers to install an observability stack (Grafana, Prometheus,
Loki, Tempo) intended for demo and testing on MicroK8s.

Files
- `observability.sh` — original script (unchanged). Review before running.
- `observability.sh.fixed` — improved, safer and documented version. Prefer this
  file for interactive use.

Usage

The fixed script supports a few environment variables and flags:

- `KUBECTL` — Override the kubectl command (default: `microk8s kubectl`).
- `HELM` — Override the helm command (default: `microk8s helm3`).
- `NAMESPACE` — Namespace to install into (default: `observability`).
- `DRY_RUN` — If set to `true` the script will print the commands instead of
  executing them.

Examples

Run using the MicroK8s defaults:

```bash
./observability.sh.fixed
```

Run with system `kubectl`/`helm` and install into `istio-monitoring`:

```bash
KUBECTL="kubectl" HELM="helm" ./observability.sh.fixed --namespace istio-monitoring
```

Notes
- The scripts set several Helm `--set` options to enable persistence and storage
  class `ceph-rbd`. Adjust these settings for your environment.
- These manifests are intended for testing/demos. Review and adapt for
  production (security, sizing, retention, backups).


References
- [Istio:](https://istio.io)
- [Grafana Helm Charts:](https://grafana.github.io/helm-charts)
- [Prometheus community Helm charts:](https://prometheus-community.github.io/helm-charts)
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

License / Notes
- These scripts and manifests are provided for testing and demo usage. Review and adapt for production.