# MicroCeph — Configuration, testing and operational notes

Purpose
- Collection of scripts and manifests to configure and validate MicroCeph (MicroCloud Ceph),
  create pools/filesystems, enable RGW, set up dashboard and telemetry, and run storage tests
  (single-threaded and parallel fio tests) against CephFS.

Contents
- MicroCeph.sh — top-level configuration (mgr modules, RGW enablement, dashboard user).
- Micro_CephPool.sh — create block pools and CephFS pools/filesystem and LXD storage entries.
- Micro_delete_CephPool.sh — delete pools (idempotent checks).
- Micro_CephFSPool.sh — create CephFS pools and filesystem.
- Micro_delete_CephFSPool.sh — delete CephFS filesystem and pools.
- test/ — local shell-based CephFS single-file throughput test (cephfs_test.sh).
- test_k8s/ — Kubernetes Job + ConfigMap for running fio against CephFS + example PVC + helper scripts.

Quick-start checklist
1. Ensure host prerequisites
   - Ubuntu 22.04+, snap microceph installed and healthy.
   - Commands available: microceph (or microceph.ceph), ceph, radosgw-admin, lxc (LXD), curl.
2. Run configuration
   - Make scripts executable:
     sudo chmod +x MicroCeph.sh Micro_CephPool.sh Micro_CephFSPool.sh
   - Execute with sudo (scripts perform privileged Ceph operations):
     sudo ./MicroCeph.sh
3. Create Pools / CephFS (if needed):
   - sudo ./Micro_CephPool.sh -n <poolname> -p <pgnum> -H "host1,host2"
   - sudo ./Micro_CephFSPool.sh -n <poolname> -p <pgnum> -H "host1,host2"
4. Validate
   - sudo microceph.ceph status
   - sudo microceph.ceph mgr services
   - sudo microceph.radosgw-admin user info --uid=admin

Security & operational guidance
- Run these scripts in staging first. Many commands are destructive (pool delete, fs rm).
- Avoid embedding secrets or long-lived passwords in files. Use environment variables or a secret store.
- Dashboard exposure: do not expose the Ceph dashboard publicly. Use internal network, VPN or require authentication.
- RGW: ensure firewall rules and object gateway ACLs are configured if exposing RGW.

Testing procedures
- Local (host) single-file test:
  - Configure test target mount (e.g. /data or /mnt/ceph).
  - sudo ./test/cephfs_test.sh  # default 1024 MiB; configure via env vars FILE_SIZE_MB, TARGET, KEEP_DEST
- Kubernetes (parallel fio) test:
  1. Edit `test_k8s/cephfs-test-pvc.yaml` to match your CephFS StorageClass and namespace.
  2. Apply PVC: sudo microk8s kubectl apply -f test_k8s/cephfs-test-pvc.yaml
  3. Apply fio ConfigMap and Job:
     sudo microk8s kubectl -n rook-ceph apply -f test_k8s/fio-cephfs-jobfile.yaml
     sudo microk8s kubectl -n rook-ceph apply -f test_k8s/cephfs-fio-test.yaml
  4. Wait for Job completion:
     sudo microk8s kubectl -n rook-ceph wait --for=condition=complete job/cephfs-fio-test --timeout=900s
  5. Collect results: use `collect_fio_results.sh` (see test_k8s README).

Logging & artifacts
- fio Job writes JSON to stdout (captured by kubectl logs). Use collect_fio_results.sh to extract JSON and convert to CSV.
- For persistent artifact storage, mount a results PVC or push outputs to S3/object storage.

Troubleshooting
- microceph not found: ensure snap is installed and `microceph` is in PATH; sometimes `microceph.ceph` is the correct wrapper.
- RGW enable fails: check cluster health, OSD/MON status, and retry with logs:
  sudo journalctl -u snap.microceph.* --no-pager
- Pool create/delete permission issues: ensure mon_allow_pool_delete toggles are used (scripts handle this). Inspect `ceph health detail`.

References and further reading
- MicroCeph docs: https://canonical-microceph.readthedocs-hosted.com/
- Ceph docs: https://docs.ceph.com/
- Rook docs: https://rook.io/docs/rook/
- fio: https://fio.readthedocs.io/
- Ceph performance tuning: https://rook.io/docs/rook/latest/ceph-performance/

Contributing
- Keep secrets out of commits.
- Run `shellcheck` on modified bash scripts and validate YAML with `kubectl apply --dry-run=client`.

