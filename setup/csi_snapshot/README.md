# Rook + Ceph (MicroK8s) — Setup and Verification - CSI Snapshotter

To resolve a missing VolumeSnapshot in MicroK8s, you must manually install the Kubernetes VolumeSnapshot CRDs and the snapshot-controller. MicroK8s does not enable volume snapshots by default.Step-by-Step InstallationRun the following commands on your MicroK8s node to deploy the official external-snapshotter components:Apply the VolumeSnapshot CRDs:

````bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
````

Deploy the snapshot-controller:

````bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
````

Verify the installation:

````bash
kubectl api-resources | grep volumesnapshot
````

(You should now see volumesnapshots, volumesnapshotcontents, and volumesnapshotclasses).

Important RequirementsCSI Driver: VolumeSnapshot only works with CSI-backed storage. The default MicroK8s hostpath addon does not support snapshots out of the box. You will need to use a CSI driver (like Ceph-CSI, Longhorn, or the OpenEBS Hostpath CSI driver) that provides snapshot capabilities.VolumeSnapshotClass: You must create a specific VolumeSnapshotClass object that references your CSI driver so Kubernetes knows how to execute the snapshot.


See: https://github.com/rook/rook/issues/6819 