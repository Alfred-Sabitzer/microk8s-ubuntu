#!/usr/bin/env bash
# Collect FIO JSON output from the latest pod of the job and convert to CSV with jq.
# Usage:
#   chmod +x collect_fio_results.sh
#   ./collect_fio_results.sh [JOB_NAME] [NAMESPACE]
# Defaults: JOB_NAME=cephfs-fio-test, NAMESPACE=rook-ceph
set -euo pipefail

JOB_NAME="${1:-cephfs-fio-test}"
NAMESPACE="${2:-rook-ceph}"
KUBECTL="${KUBECTL:-microk8s kubectl}"

POD=$($KUBECTL -n "$NAMESPACE" get pod -l job-name="$JOB_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -z "$POD" ]; then
  echo "No pod found for job ${JOB_NAME} in ${NAMESPACE}" >&2
  exit 2
fi

echo "Found pod: $POD"
echo "Fetching logs..."
$KUBECTL -n "$NAMESPACE" logs "$POD" > /tmp/"${POD}".log

# Try to extract JSON block from logs (fio prints JSON to stdout)
JSON_FILE=/tmp/"${POD}".json
# naive extraction: first "{" to last "}" in log file
awk 'BEGIN{p=0} { if($0 ~ /^{/ && p==0) { p=1 } if(p==1) print }' /tmp/"${POD}".log > "${JSON_FILE}" || true

if ! grep -q '"jobs"' "${JSON_FILE}"; then
  echo "JSON not found in logs. Please check /tmp/${POD}.log" >&2
  exit 3
fi

# Convert fio JSON to CSV (header + rows)
# Fields: jobname, read_bw_kB_s, read_iops, read_clat_mean_ns, write_bw_kB_s, write_iops, write_clat_mean_ns
jq -r '
  (["jobname","read_bw_kB_s","read_iops","read_clat_mean_ns","write_bw_kB_s","write_iops","write_clat_mean_ns"] | @csv),
  (.jobs[] | [
    .jobname,
    (.read.bw // 0),
    (.read.iops // 0),
    (.read.clat.mean // 0),
    (.write.bw // 0),
    (.write.iops // 0),
    (.write.clat.mean // 0)
  ] | @csv)
' "${JSON_FILE}" > /tmp/"${POD}".csv

echo "CSV saved to /tmp/${POD}.csv"
echo "Sample output:"
head -n 20 /tmp/"${POD}".csv
echo ""
echo "To retrieve files locally:"
echo "  microk8s kubectl -n ${NAMESPACE} cp ${POD}:/tmp/fio-output.json ./fio-output-${POD}.json || true"
echo "  microk8s kubectl -n ${NAMESPACE} cp ${POD}:/tmp/fio-output.csv ./fio-output-${POD}.csv || true"