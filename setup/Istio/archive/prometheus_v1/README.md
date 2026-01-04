# Istio on MicroK8s — Prometheus integration helper

Purpose
- Helper script to extract the operator-managed Prometheus config, append example Istio scrape configs,
  and produce a draft Secret manifest for manual review and apply.

Why manual?
- Prometheus operator setups often manage Prometheus config Secrets automatically. Overwriting those Secrets
  can be reverted by the operator or cause unexpected behavior. This script prepares a reviewed manifest so
  you can apply safely after inspection.

Files
- istio_prometheus.sh — extract, prepare and produce secret manifest with appended Istio scrape configs.
- additional_scrape.yaml (generated in tmp by the script) — example scrape jobs for istiod and Envoy stats.

Prerequisites
- microk8s or kubectl in PATH (script auto-detects).
- access to the cluster/context where Prometheus is deployed.
- the script defaults to namespace `observability`. Override with NAMESPACE env var.
- Review operator documentation if you run Prometheus via Prometheus-operator.

Usage
- Dry run not implemented; script writes artifacts to a temp directory and prints manual steps.
- Example:
  NAMESPACE=observability PROM_SECRET=prometheus-kube-prom-stack-kube-prome-prometheus \
    ./prometheus_config.sh

Output
- A modified prometheus.yaml (uncompressed) and a Secret manifest file are written into a temporary directory.
- The script prints the path to the files and recommended manual commands.

1. Run the script and inspect the generated prometheus.modified.yaml carefully.
2. Adapt/validate the additional scrape configs to your environment.
3. Prefer creating a separate Secret for additionalScrapeConfigs and update the Prometheus CR to reference it:
   - This avoids fighting the operator and keeps changes explicit.
4. If you do apply the modified secret, monitor the Prometheus pod for startup issues.

Caveats
- This helper appends configs for convenience. It does not automatically update Prometheus CRs or reconcile with the operator.
- If your Prometheus stack uses different secret keys or names, set PROM_SECRET env var accordingly.

References
- [How to Monitor Kubernetes CronJobs with Prometheus - A Guide](https://signoz.io/guides/is-there-a-way-to-monitor-kube-cron-jobs-using-prometheus/)
- [Prometheus operator docs - Additional Scrape Configuration](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/additional-scrape-config.md)
- [Prometheus operator docs](https://github.com/prometheus-operator/prometheus-operator)
- [Istio metrics scraping docs](https://istio.io/latest/docs/ops/integrations/prometheus/)
- [Configurarion hints](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)