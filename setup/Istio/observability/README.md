# Observability Stack

By default the microk8s-addon is deployed without pvc (everthing is in "empty dir"). That means everthing is forgotten, when something is restarting.
So we install the version from the real community.


## Notes
- Test in staging before deploying to production.
- Keep secrets and private keys out of version control.

## References
- [Setup with pvc](https://blog.devops.dev/deploying-kube-prometheus-stack-with-persistent-storage-on-kubernetes-cluster-24473f4ea34f)
- [Resizing Volumes](https://prometheus-operator.dev/docs/platform/storage/#resizing-volumes)
- [Adding PVC](https://github.com/prometheus-community/helm-charts/issues/2816)
- [Configurarion hints](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)

