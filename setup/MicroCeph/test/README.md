# CephFS local test helpers

Purpose
- Simple, host-side CephFS throughput test useful for quick sanity checks and baseline comparisons.

Files
- `cephfs_test.sh` — single-file write+read throughput test using dd (configurable).
  - Env variables:
    - FILE_SIZE_MB (default 1024)
    - TARGET (default /data)
    - KEEP_DEST (set true to preserve destination file)
    - USE_DIRECT (0/1; try direct I/O if supported)
  - Example:
    sudo FILE_SIZE_MB=512 TARGET=/mnt/ceph KEEP_DEST=true ./cephfs_test.sh

Best practices
- Run tests when cluster is idle for stable results.
- Use multiple runs and median/average results.
- For accurate write performance, use direct I/O (oflag=direct) when supported.
- Monitor node and network metrics during tests to spot bottlenecks.

Limitations
- dd provides a simple pattern; it does not model concurrency or small-random I/O workloads.
- For realistic production workloads use fio (see test_k8s).

Troubleshooting
- Permission denied when writing to TARGET: ensure mount is writable and you run as appropriate user (sudo may be required).
- Drop caches may not work inside containers or unprivileged environments.

References
- dd manual: https://man7.org/linux/man-pages/man1/dd.1.html
- Ceph/Rook performance: https://rook.io/docs/rook/latest/ceph-performance/