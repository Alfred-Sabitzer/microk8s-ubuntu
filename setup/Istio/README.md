# Istio on MicroK8s — Setup, Validation and Demo

Purpose
- Opinionated, repeatable guidance and helper scripts to install Istio on MicroK8s, validate Istio manifests,
  and deploy/verify demo and observability integrations (ingress, egress, Prometheus/Grafana).

Prerequisites
- MicroK8s installed and running, or kubectl context pointed to target cluster.
- Helm (v3+) installed for chart operations.
- Optional: istioctl installed for deeper validation (istioctl analyze, verify-install).
- Enough cluster resources for Istio control plane and addons.

Layout (important files)
- Istio.sh
  - Idempotent installer (helm upgrade --install), readiness checks, optional demo deployment.
  - Flags: --deploy-demo, --skip-disable, --wait <s>.
- istio_prepare.sh
  - Pre-checks: kubectl connectivity, optional istioctl verify-install.
- istio_validate.sh
  - Runs istioctl analyze (if present) and kubectl apply --dry-run=client on manifests.
- ingress/istio_ingress.sh
  - Ordered, safe apply for ingress manifests (dry-run + confirmation).
- egress/
  - egress manifests (rook Ceph, Prometheus examples) and helper scripts.
- observability/
  - Grafana / Prometheus manifests and helper scripts (observability_apply.sh, restart helpers).
- prometheus/istio_prometheus.sh
  - Helper that extracts operator-managed Prometheus config and prepares a safe secret manifest for manual apply.
- bookinfo/
  - bookinfo.sh — demo deploy script (dry-run, pvc support).
- observability/test/
  - busybox_rwo.yaml, busybox_rwx.yaml and kexec scripts for storage testing.
- restart_observability.sh
  - Restart controllers and pods in a namespace (used after enabling mesh injection or updating sidecars).

Recommended workflow
1. Validate environment:
   - Ensure kubectl/microk8s available and context is correct.
   - Optional: istioctl verify-install / istioctl analyze for cluster state.
     microk8s kubectl version --short
     istioctl version ; istioctl verify-install

2. Install Istio (idempotent):
   - ./Istio.sh
   - To deploy demo: ./Istio.sh --deploy-demo

3. Validate and apply Istio manifests:
   - ./istio_validate.sh <manifest-dir>
   - ingress/istio_ingress.sh --dry-run
   - ingress/istio_ingress.sh --yes

4. Observability / Prometheus:
   - Inspect observability/observability-pvc.yaml and adjust storageClassName.
   - Use observability/observability_apply.sh --dry-run then apply.
   - Use prometheus/istio_prometheus.sh to prepare Prometheus operator changes; apply Secret manually and prefer operator-aware methods.

5. Egress / External services:
   - Inspect egress manifests (egress/istio_egress_rook_ceph.yaml, istio_egress_prometheus.yaml).
   - Use istio_validate.sh before applying.
   - Ensure mesh-side VirtualService routes traffic to istio-egressgateway.

Key recommendations and hardening
- Always run istioctl analyze and kubectl apply --dry-run=client before applying manifests.
- Prefer explicit gateway references: list gateways as "istio-system/<gateway-name>" in VirtualService.
- Use AuthorizationPolicy + NetworkPolicy for defense-in-depth.
- Choose TLS origination mode deliberately:
  - SIMPLE (gateway terminates TLS) — store certs in istio-system.
  - PASSTHROUGH (backend terminates TLS) — do not terminate at gateway.
- For operator-managed Prometheus, prefer creating a separate Secret for additionalScrapeConfigs and reference it in the Prometheus CR instead of overwriting operator-managed Secrets.

Common commands
- Validate YAML locally:
  microk8s kubectl apply --dry-run=client -f <file>
- Istio analysis:
  istioctl analyze <path-or-cluster>
- Check resources:
  microk8s kubectl -n istio-system get pods,svc
  microk8s kubectl -n observability get pods,pvc,deploy -o wide

Troubleshooting pointers
- Pods not ready: kubectl -n <ns> describe pod <pod>; kubectl -n <ns> logs <pod> -c <container>
- Sidecars not injected: ensure target namespace has label `istio-injection=enabled` or inject manually.
- Prometheus/Operator issues: inspect operator logs and avoid direct overwrites of operator-managed Secrets.

Contributing / Editing manifests
- Keep API versions consistent (networking.istio.io/v1beta1 where supported).
- Use istioctl analyze to detect deprecated APIs and configuration issues.
- Test changes with --dry-run and in a non-production namespace first.

References
- [Istio docs:](https://istio.io/latest/docs/)
- [Istio Installation prerequistes:](https://istio.io/latest/docs/ambient/install/platform-prerequisites/)
- [Install Istio with helm](https://istio.io/latest/docs/setup/install/helm/)
- [Ambient Installation with helm](https://ambientmesh.io/docs/setup/installation/)
- [Install all Istio-components with helm](https://artifacthub.io/packages/helm/code4devs/istio-all)
- [istioctl analyze:](https://istio.io/latest/docs/ops/diagnostic-tools/istioctl-analyze/)
- [Deploy Istio](https://gist.github.com/Realiserad/391855c4a0fb0072994e5ad2a53d65c0)
- [MicroK8s Istio addon::]( https://microk8s.io/docs/addon-istio)
- [Prometheus Operator:](https://github.com/prometheus-operator/prometheus-operator)
- [cert-manager:](https://cert-manager.io/docs/)

License / Notes
- These scripts and manifests are provided for testing and demo usage. Review and adapt for production.