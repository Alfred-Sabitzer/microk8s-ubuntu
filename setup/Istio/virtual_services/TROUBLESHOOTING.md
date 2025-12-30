# Troubleshooting — common issues and fixes

1) "kubectl or microk8s not found"
- Symptoms: script exits with a message about kubectl not in PATH.
- Fix: ensure `kubectl` or `microk8s` is installed and on PATH or invoke the script with the proper environment (e.g. `PATH=/snap/bin:$PATH ./virtual_services.sh`).

2) `envsubst` errors or variables not substituted
- Symptoms: YAMLs still contain `${K8S_ENVIRONMENT}` after apply.
- Fix: install `envsubst` (Debian/Ubuntu: `sudo apt-get install gettext-base`) and export `K8S_ENVIRONMENT` before running: `export K8S_ENVIRONMENT=staging`.

3) `kubectl apply` transient failures
- Symptoms: API server errors, 500s, or apply fails intermittently.
- Fix: re-run the script (it retries). For persistent failures, inspect API server and cert-manager logs. Use `kubectl apply --server-side` or dry-run to validate.

4) YAML linting issues
- Symptoms: `yamllint` reports indentation, trailing-spaces or missing document start.
- Fixes:
  - Add `---` at top of YAML documents where missing.
  - Remove trailing spaces and fix indentation (use 2 spaces for YAML mapping levels).
  - Use `yamllint` to validate modified files before apply.

5) Files with stray whitespace in filenames
- Symptoms: tooling fails to find files or odd errors when listing files.
- Fix: remove/rename files — this repository had a few trailing-space filenames which were fixed.

6) Authorization and access issues after deploy
- Check `AuthorizationPolicy` and NetworkPolicy rules that might block traffic to the ingress gateway. Use `kubectl -n istio-system get authorizationpolicy` and `kubectl -n istio-system describe <resource>` to inspect.

Helpful commands

```bash
# Lint a YAML file
yamllint 01_virtual-service-grafana-mutual.yaml

# Dry-run apply
kubectl apply -f 01_virtual-service-grafana-mutual.yaml --dry-run=client

# Describe a VirtualService
kubectl -n istio-system describe virtualservice grafana-mutual

# Check cert-manager for certificate issuance problems
kubectl -n cert-manager logs -l app=cert-manager --tail=200
```

If you want, I can patch a small script to automatically run `yamllint` and fix trivial issues (strip trailing spaces, add document starts) across this directory — tell me if you want that automated fix.
