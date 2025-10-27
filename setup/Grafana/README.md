# Grafana setup

A working Grafana installation also requires some dashboards/reports.

## Preparation

Grafana must already be running. The admin password has already been updated in the corresponding Kubernetes secret. This is done in ClusterSetup/MicroK8SDashboard.sh.

## Helper scripts

The two helper scripts can save reports from Grafana locally or reload them back into Grafana:

```bash
./Export_all_Reports.sh
./Import_all_Reports.sh
```

This allows you to share custom reports with other Grafana installations.
