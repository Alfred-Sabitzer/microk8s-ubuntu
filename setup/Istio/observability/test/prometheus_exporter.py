#!/usr/bin/env python3
# See https://gist.github.com/rchakode/8c362c23876b82c85e997c029b076540
# for reference
# This script exposes system resource usage metrics for Prometheus
# It exposes CPU and Memory usage every 5 minutes on port 9999
# Usage:
#   pip install prometheus_client psutil
#   python3 prometheus_exporter.py
# Then configure Prometheus to scrape metrics from http://<host>:9999/metrics
#
#
import prometheus_client
import time
import psutil
import sys

UPDATE_PERIOD = 300
SYSTEM_USAGE = prometheus_client.Gauge('system_usage',
                                       'Hold current system resource usage',
                                       ['resource_type'])

if __name__ == '__main__':
  prometheus_client.start_http_server(9999)
  
while True:
  SYSTEM_USAGE.labels('CPU').set(psutil.cpu_percent())
  SYSTEM_USAGE.labels('Memory').set(psutil.virtual_memory()[2])
  print("metric: CPU: {}%, Memory: {}%".format(psutil.cpu_percent(), psutil.virtual_memory()[2]))  
  sys.stdout.flush()
  time.sleep(UPDATE_PERIOD)
 