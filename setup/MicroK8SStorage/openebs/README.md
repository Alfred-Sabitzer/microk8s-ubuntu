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

## References

- [OpenEBS on MicroK8s](https://microk8s.io/docs/addon-openebs)

