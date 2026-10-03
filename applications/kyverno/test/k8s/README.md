# Kyverno deployment on MicroK8s

This folder contains several deployment for testing the image-checkin rule.

Expected behaviour is

```bash
ansible@k8stest:~/gitlab/microk8s-ubuntu/applications/kyverno/test/k8s$ kubectl apply -f .
deployment.apps/dummy-signed created
deployment.apps/dummy-wrong-repo created
Error from server: error when creating "deployment_unsigned.yaml": admission webhook "ivpol.validate.kyverno.svc-fail-finegrained-check-image" denied the request: Policy check-image failed: All container images must have a valid Cosign signature.
Error from server: error when creating "deployment_wrong_repo.yaml": admission webhook "ivpol.validate.kyverno.svc-fail-finegrained-check-image" denied the request: Policy check-image failed: All container images must have a valid Cosign signature.
```

The corresponding rule is

```bash
ansible@k8stest:~/gitlab/microk8s-ubuntu/applications/kyverno/test/k8s$ k get imagevalidatingpolicies.policies.kyverno.io 
NAME          AGE   READY
check-image   12m   true
```

Cleanup can be done

```bash
ansible@k8stest:~/gitlab/microk8s-ubuntu/applications/kyverno/test/k8s$ k delete -f .
deployment.apps "dummy-signed" deleted from kyverno-test namespace
deployment.apps "dummy-wrong-repo" deleted from kyverno namespace
Error from server (NotFound): error when deleting "deployment_unsigned.yaml": deployments.apps "dummy-unsigned" not found
Error from server (NotFound): error when deleting "deployment_wrong_repo.yaml": deployments.apps "dummy-wrong-repo" not found
```
