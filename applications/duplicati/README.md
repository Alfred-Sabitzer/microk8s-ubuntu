# Duplicate Backup

https://duplicati.com/


## Architecture

                  MicroK8s Cluster
                ┌───────────────────────┐
                │                       │
Browser ───────►│ Istio Gateway         │
                │       │               │
                │       ▼               │
                │ Duplicati Service     │
                │       │               │
                │       ▼               │
                │ Duplicati Pod         │
                │       │               │
                │       ▼               │
                │ PVC /data             │
                │                       │
                └───────┬───────────────┘
                        │
              ┌─────────┴──────────┐
              │                    │
              ▼                    ▼
       Externer Ceph          Externer SFTP
       RGW / S3               SSH / SFTP
       (Source)               (Target)

##
