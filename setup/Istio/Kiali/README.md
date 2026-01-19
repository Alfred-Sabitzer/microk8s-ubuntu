# Kiali on sudo microk8s — Setup and Test

This folder contains a Helm-based installer script, sample values, and test helpers to install Kiali on sudo microk8s and verify access.

## Project overview
- `Kiali.sh` — installs Kiali via `sudo microk8s helm` into a namespace (default `kiali`) and waits for readiness.
- `kiali-values.yaml` — sample Helm values for quick testing (uses anonymous auth for demo only).
- `test/kexec_demo.sh` — helper to list pods/services and port-forward the Kiali UI locally.

## Prerequisites
- sudo microk8s installed and running
- User in `microk8s` group or run with `sudo`
- `microk8s` CLI available in PATH (script uses sudo microk8s helm and sudo microk8s kubectl)
- Internet access to fetch Helm chart from https://kiali.org/helm-charts

## Usage

1. Make the installer executable:
   ```bash
   chmod +x Kiali.sh
   ```

2. Install Kiali with defaults:
   ```bash
   sudo ./Kiali.sh
   ```

3. Install with custom namespace or values:
   ```bash
   sudo ./Kiali.sh --namespace monitoring --values /path/to/values.yaml
   ```

4. Port-forward to access the UI locally:
   ```bash
   cd test
   ./kexec_demo.sh
   # then open http://localhost:20001/kiali
   ```

## Configuration
- The included `kiali-values.yaml` enables `anonymous` authentication for convenience only. Change `auth.strategy` to `login` or configure OpenID/OAuth for production.
- To expose Kiali externally, change `service.type` in the values file to `LoadBalancer` (requires MetalLB or cloud LB) or `NodePort`. Prefer secure auth before exposing.

## Testing & Verification
- Check pods and services:
  ```bash
  sudo microk8s kubectl -n kiali get pods,svc,deploy -o wide
  ```
- Use the port-forward helper and open the UI:
  ```bash
  cd test
  ./kexec_demo.sh
  curl -sSf http://localhost:20001/kiali/healthz
  ```

## Troubleshooting
- If chart install fails, inspect helm/kubectl output and pod logs:
  ```bash
  sudo microk8s kubectl -n kiali get events --sort-by='.lastTimestamp'
  sudo microk8s kubectl -n kiali logs -l app.kubernetes.io/name=kiali
  ```
- Ensure Prometheus is reachable in-cluster or set `external_services.prometheus.url` in values.

## Cleanup
- Uninstall via Helm:
  ```bash
  sudo microk8s helm -n kiali uninstall kiali || true
  sudo microk8s kubectl delete namespace kiali || true
  ```

## Security notes
- Do NOT use `anonymous` auth in production. Configure secure auth (login, OIDC) and HTTPS.
- Do not commit secrets or production credentials to the repository.

## References
- [Kiali Helm charts](https://kiali.org/helm-charts)
- [Kiali docs](https://kiali.io/documentation)
- [How to access kiali](https://kiali.io/docs/installation/installation-guide/accessing-kiali/)
- [access kiali]( https://istio.io/latest/docs/tasks/observability/kiali/)
 -[Istio concept explanation](https://sigridjin.medium.com/istio-and-service-mesh-c1a76a1b0593)
