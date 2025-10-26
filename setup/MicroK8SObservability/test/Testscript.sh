#!/bin/bash
############################################################################################
# This script test ceph integration and observability.
############################################################################################
set -euo pipefail

MGRS=("micro4.slainte.at" "micro1.slainte.at" "micro2.slainte.at")
REACH=()
for t in "${MGRS[@]}"; do
  # test HTTP reachability
  echo "Checking $t"
  if curl -sSf "http://$t:9283/api/v1/metrics" >/dev/null; then
    echo "OK: $t reachable"
    REACH+=("$t")
  else
    echo "FAIL: $t unreachable"
  fi
done

echo "Reachable MGRs: ${#REACH[@]}"
if [ "${#REACH[@]}" -eq 0 ]; then
  echo "Error: No reachable MGRs found. Exiting." >&2
  exit 1
fi

for t in "${REACH[@]}"; do
  echo "Checking $t"
  # expect to see Prometheus-formatted metrics (e.g., ceph_cluster_total_bytes, ...)
  curl -sSf "http://$t:9283/api/v1/metrics"
done

exit

# test HTTP reachability
curl -sfS http://micro4.slainte.at:9283/api/v1/metrics | head -n 5

# inside prometheus container or any host with access:
curl -s http://prometheus.monitoring.svc.cluster.local:9090/api/v1/targets | jq '.data.activeTargets[] | {scrapePool:.scrapePool, lastScrape:.lastScrape, health:.health}'
