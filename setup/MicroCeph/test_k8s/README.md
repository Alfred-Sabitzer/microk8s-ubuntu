# CephFS Kubernetes FIO tests (parallel workload)

Purpose
- Run parallel multi-threaded I/O tests (fio) inside the cluster against a CephFS PVC to simulate production-like patterns.

Prerequisites
- Kubernetes cluster with Rook/CephFS; a PVC bound to CephFS (ReadWriteMany) is required.
- `microk8s kubectl` or kubectl configured for the cluster.
- `jq` installed locally for JSON -> CSV conversion (or run conversion inside a container).

Files
- `cephfs-test-pvc.yaml` — example PVC (adjust `storageClassName`, namespace, size).
- `fio-cephfs-jobfile.yaml` — ConfigMap with fio jobfile (job parameters).
- `cephfs-fio-test.yaml` — Kubernetes Job that runs fio and emits JSON to stdout.
- `collect_fio_results.sh` — (in repo root test/) fetches Job pod logs, extracts fio JSON and writes CSV.

Quick run
1. Create namespace and PVC (edit as needed):
   microk8s kubectl apply -f cephfs-test-pvc.yaml
2. Create ConfigMap with fio jobfile:
   microk8s kubectl apply -f fio-cephfs-jobfile.yaml
3. Run Job:
   microk8s kubectl apply -f cephfs-fio-test.yaml
4. Wait:
   microk8s kubectl -n rook-ceph wait --for=condition=complete job/cephfs-fio-test --timeout=900s
5. Collect and convert:
   ./collect_fio_results.sh cephfs-fio-test rook-ceph
   # outputs CSV under /tmp (or download with kubectl cp)

Tuning tips
- Adjust `numjobs`, `iodepth`, `bs`, and `runtime` in the fio jobfile to match expected workload.
- For metadata-heavy workloads reduce `bs` and increase random IO ratio.
- Use multiple PVCs and concurrent Jobs to stress the cluster-scale behaviour.

Result interpretation
- FIO JSON contains per-job metrics (bw, iops, latencies). Compare read vs write, and note if latencies increase with load.
- Use CSV results to plot trends or feed into performance dashboards.

Cleanup
- Delete job and configmap:
  microk8s kubectl -n rook-ceph delete job/cephfs-fio-test
  microk8s kubectl -n rook-ceph delete configmap/fio-cephfs-jobfile
- Remove PVC only when no longer used:
  microk8s kubectl -n rook-ceph delete pvc/cephfs-test-pvc

References
- fio docs: https://fio.readthedocs.io/
- Rook CephFS: https://rook.io/docs/rook/latest/ceph-filesystem/
- Example fio jobfile docs: https://fio.readthedocs.io/en/latest/fio_doc.html
- K8S Example https://github.com/joshuarobinson/fio-kubernetes
