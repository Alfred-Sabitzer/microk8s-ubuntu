# Ceph Prometheus

Target is to integrate the ceph-cluster into prometheus monitoring.

```bash
Ceph Cluster (external)
 ├─ ceph-mgr (Prometheus exporter :9283)
 ├─ ceph-mon (via mgr)
 ├─ ceph-osd (via mgr)
 └─ (optional) ceph-rgw exporter

        ↓ (HTTPS / HTTP)

sudo microk8s Cluster
 ├─ Prometheus
 ├─ Grafana
 └─ ServiceMonitor / static scrape config
```

