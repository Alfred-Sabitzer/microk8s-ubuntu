# Kyverno deployment on MicroK8s

This script generates two images. One can be signed, and the other not.
Purpose is for testing kyverno rules.

The corresponding rule is

```bash
ansible@k8stest:~/gitlab/microk8s-ubuntu/applications/kyverno/test/k8s$ k get imagevalidatingpolicies.policies.kyverno.io 
NAME          AGE   READY
check-image   12m   true
```
Image can be build and pushed with


```bash
cd applications/kyverno/test/podman
HARBOR_USER="..." HARBOR_PASSWORD="..." ./do_test_podman.sh
```
