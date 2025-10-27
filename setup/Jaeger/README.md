# Jaeger on MicroK8s — Setup, Demo & Tests

This folder provides an idempotent installer script to enable Jaeger on MicroK8s, an optional demo manifest to generate traces (HotROD example), and helper utilities to access the Jaeger UI.

Files:
- Jaeger.sh — enable and verify MicroK8s Jaeger addon (idempotent, retries, progress messages)
- test/demo-hotrod.yaml — demo HotROD application (deploys into namespace `jaeger-demo`)
- test/kexec_jaeger.sh — helper for port-forwarding the Jaeger UI or exec into demo pods
- README.md — this file

Project overview:
- Enable the Jaeger addon on MicroK8s for tracing/observability.
- Optionally deploy a demo app that reports traces to Jaeger.
- Provide easy local access to the Jaeger UI (port-forward) and helper commands to validate traces.

Prerequisites:
- MicroK8s installed and running
- User in `microk8s` group or run scripts with sudo
- Network access to pull container images used by Jaeger and demo app

Usage:
1. Make the installer and helpers executable:
   ```bash
   chmod +x Jaeger.sh test/kexec_jaeger.sh
   ```

2. Enable Jaeger only:
   ```bash
   sudo ./Jaeger.sh
   ```

3. Enable Jaeger and deploy demo:
   ```bash
   sudo ./Jaeger.sh --deploy-demo
   ```

4. Access Jaeger UI locally:
   ```bash
   cd test
   ./kexec_jaeger.sh          # port-forward jaeger-query to http://localhost:16686
   # then open http://localhost:16686 in browser
   ```

Testing:
- After demo deployment, generate traffic against the demo service (e.g., curl the hotrod service) and open Jaeger UI to search for services/traces.
- Check pod status:
  ```bash
  microk8s kubectl -n jaeger get pods
  microk8s kubectl -n jaeger-demo get pods
  ```

Troubleshooting:
- If `microk8s enable jaeger` fails, run:
  ```bash
  microk8s status --wait-ready
  microk8s kubectl -n jaeger get pods,svc,deploy -o wide
  microk8s kubectl -n jaeger logs <pod>
  ```
- If demo images are unavailable, replace `jaegertracing/example-hotrod:1.0` in `demo-hotrod.yaml` with an image accessible in your environment or build/push it to a registry the cluster can access.

Cleanup:
- Remove demo:
  ```bash
  microk8s kubectl delete -f test/demo-hotrod.yaml || true
  microk8s kubectl delete namespace jaeger-demo || true
  ```
- Disable Jaeger addon:
  ```bash
  microk8s disable jaeger
  ```

Security notes:
- Do not expose Jaeger UI to untrusted networks without authentication.
- Review container images in demo manifests before running in production.
- Avoid committing secrets or credentials to the repository.

References:
- Jaeger documentation: https://www.jaegertracing.io/docs/
- MicroK8s addons: https://microk8s.io/docs/addons