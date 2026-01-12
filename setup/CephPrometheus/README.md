# Ceph Prometheus

Target is to integrate the ceph-cluster into prometheus monitoring.

Ceph Cluster (external)
 ├─ ceph-mgr (Prometheus exporter :9283)
 ├─ ceph-mon (via mgr)
 ├─ ceph-osd (via mgr)
 └─ (optional) ceph-rgw exporter

        ↓ (HTTPS / HTTP)

MicroK8s Cluster
 ├─ Prometheus
 ├─ Grafana
 └─ ServiceMonitor / static scrape config

