# OpenEBS on MicroK8s

This setup enables [OpenEBS](https://openebs.io/) as a storage solution for your MicroK8s cluster.

## Prerequisites

- [MicroK8s](https://microk8s.io/) installed and running
- User in the `microk8s` group or root privileges

## Usage

```bash
chmod +x MicroK8SOpenEBS.sh
./MicroK8SOpenEBS.sh
```

The script will:
- Enable the `hostpath-storage` addon
- Disable and re-enable the OpenEBS addon for a clean state
- Set OpenEBS Jiva as the default storage class
- List and verify storage classes

## Customization

- To change the storage path for OpenEBS hostpath, edit and uncomment the relevant lines in the script.

## Troubleshooting

- Check storage classes:
  ```bash
  microk8s kubectl get storageclass
  ```
- Check OpenEBS pods:
  ```bash
  microk8s kubectl -n openebs get pods
  ```
- For more info, see [OpenEBS documentation](https://openebs.io/docs/).

## Testing

You can test your OpenEBS setup with the provided `busybox.yaml`:

```bash
microk8s kubectl apply -f busybox.yaml
microk8s kubectl get pods
```

This will deploy a BusyBox pod writing logs to two different OpenEBS-backed PersistentVolumeClaims.

## Cleanup

To remove the test resources:

```bash
microk8s kubectl delete -f busybox.yaml
```

## References

- [OpenEBS on MicroK8s](https://microk8s.io/docs/addon-openebs)

# openebs-jiva-default

This will only work in a cluster with at least 3 nodes.

```yaml
apiVersion: openebs.io/v1
kind: JivaVolumePolicy
metadata:
  annotations:
    meta.helm.sh/release-name: openebs
    meta.helm.sh/release-namespace: openebs
  creationTimestamp: "2025-05-30T19:25:42Z"
  generation: 1
  labels:
    app.kubernetes.io/managed-by: Helm
  name: openebs-jiva-default-policy
  namespace: openebs
  resourceVersion: "31247"
  uid: 0bf6e75f-18d8-497a-a345-f236ed9e42b5
spec:
  replicaSC: openebs-hostpath
  target:
    replicationFactor: 3

```

Attempt with busybox and only one node will lead to

```bash
k get pvc --all-namespaces 
NAMESPACE   NAME                                                          STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS               VOLUMEATTRIBUTESCLASS   AGE
default     hostpath                                                      Bound     pvc-096ea004-3ca6-4d1c-8f69-256dee6c317e   1Mi        RWO            openebs-hostpath           <unset>                 71s
default     jivacsidefault                                                Bound     pvc-60dbfd7c-5b41-4acc-926c-c52ca820e7ae   1Mi        RWO            openebs-jiva-csi-default   <unset>                 71s
openebs     openebs-pvc-60dbfd7c-5b41-4acc-926c-c52ca820e7ae-jiva-rep-0   Bound     pvc-d45de734-6f27-4aae-962a-c500e550c6e8   1Gi        RWO            openebs-hostpath           <unset>                 68s
openebs     openebs-pvc-60dbfd7c-5b41-4acc-926c-c52ca820e7ae-jiva-rep-1   Pending                                                                        openebs-hostpath           <unset>                 68s
openebs     openebs-pvc-60dbfd7c-5b41-4acc-926c-c52ca820e7ae-jiva-rep-2   Pending                                                                        openebs-hostpath           <unset>                 68s
```


