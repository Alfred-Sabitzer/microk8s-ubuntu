# Observability kube-prom-stack

By default the microk8s-addon is deployed without pvc (everthing is in "empty dir"). That means everthing is forgotten, when something is restarting.
So we install the version from the real community.


## Apply Disk to the system.

```bash
# create namespace
microk8s kubectl apply -f ./kube-prom-namespace-dis.yaml
# create pvc
microk8s kubectl apply -f ./kube-prom-pvc.yaml
```

## Redeploy helm with adopted values

```bash
sudo microk8s helm3 install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace observability \
    --create-namespace \
    --set=alertmanager.persistentVolume.existingClaim=kube-prometheus-stack-pvc \
    --set=server.persistentVolume.existingClaim=kube-prometheus-stack-pvc \
    --set=grafana.persistentVolume.existingClaim=kube-prometheus-stack-pvc 

```

## check and observe values

```bash
helm get values kube-prom-stack --namespace observability --all > kube-prom-stack-values.yaml
```
This is just an example how to get values from the installed version.

## References
- [Setup with pvc](https://blog.devops.dev/deploying-kube-prometheus-stack-with-persistent-storage-on-kubernetes-cluster-24473f4ea34f)
- [Resizing Volumes](https://prometheus-operator.dev/docs/platform/storage/#resizing-volumes)
- [Adding PVC](https://github.com/prometheus-community/helm-charts/issues/2816)
- [Configurarion hints](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)

## Notes
- Test in staging before deploying to production.
- Keep secrets and private keys out of version control.
