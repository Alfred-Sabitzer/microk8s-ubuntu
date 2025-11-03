# Observability update values

By default the microk8s-addon is deployed without pvc (everthing is in "empty dir"). That means everthing is forgotten, when something is restarting.
So we add some pvc to the deployment.


## Apply Disk to the system.

```bash
alfred@lxd:~$ kubectl apply -f pvc.yaml 
persistentvolumeclaim/kube-prometheus-stack-pvc created
alfred@lxd:~$ 
```

## Redeploy helm with adopted values

```bash
helm upgrade --reuse-values kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace observability \
   --set=alertmanager.persistentVolume.existingClaim=kube-prometheus-stack-pvc \
   --set=server.persistentVolume.existingClaim=kube-prometheus-stack-pvc \
   --set=grafana.persistentVolume.existingClaim=kube-prometheus-stack-pvc

sudo helm upgrade --reuse-values kube-prom-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
   --namespace  observability \
   --set=alertmanager.persistentVolume.existingClaim=kube-prometheus-stack-pvc \
   --set=server.persistentVolume.existingClaim=kube-prometheus-stack-pvc \
   --set=grafana.persistentVolume.existingClaim=kube-prometheus-stack-pvc

sudo helm upgrade kube-prom-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
   --values ./kube-prom-stack-values.yaml
   --namespace  observability \
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
