# Test namespace fixtures

This folder defines the namespace and minimal access objects used by the Kyverno tests.

## Included manifests

- `namespace.yaml`: creates the `test` namespace and adds labels/annotations used by the cluster policies.
- `networkpolicy.yaml`: restricts ingress/egress traffic for the namespace and enforces a default deny posture.
- `harbor-cosign.yaml`: defines the external secret for Harbor credentials and cosign material.
- `harbor-pull.yaml`: defines the pull secret used for private registry access.
- `rbac.yaml`: grants the Kyverno admission controller read access to the `harbor-cosign` secret.

## Apply

```bash
kubectl apply -f applications/kyverno/test/test_namespace/
```

## Remove

```bash
kubectl delete -f applications/kyverno/test/test_namespace/
```

## Notes

- The namespace name is intentionally fixed to `test` and is assumed by the K8s test policy manifests.
- The `RoleBinding` in `rbac.yaml` targets the `kyverno-admission-controller` service account in the `kyverno` namespace.
- Validate the secret names and namespace values before reusing the fixtures in a different cluster.
