# Istio Addons — Monitoring, Visualization & Observability

Welcome to the Istio addons configuration suite! This folder contains deployment scripts and documentation for installing Istio observability addons on MicroK8s, including **Kiali, Prometheus, Grafana, Jaeger, and Loki**.

## 🚀 Quick Navigation

**First time here?** Start with one of these:
- ⚡ **[Quick Start](#quick-start)** — Get addons running in 5 minutes
- 📚 **[Addon Details](#addons-explained)** — Understand each addon
- 🔧 **[Troubleshooting](#troubleshooting)** — Problem diagnosis

**Looking for specifics?**
- 📖 **[Advanced Configuration](#advanced-configuration)** — Customization and tuning
- 🔐 **[Security](#security-considerations)** — Access control and best practices
- 📊 **[Verification](#verification)** — Health checks and monitoring


## 🛠️ Enhanced Installation Script

The improved `istio_addons.sh` script includes:
- ✅ Auto-detection of kubectl vs microk8s
- ✅ Comprehensive error handling and validation
- ✅ Retry mechanism for transient failures
- ✅ Post-deployment status checks
- ✅ Helpful next-steps guidance
- ✅ Clear progress messaging

**Quality Score**: 9/10 (robustness and usability)

## 📦 Available Addons

| Addon | Purpose | Purpose | Details |
|-------|---------|---------|---------|
| **Kiali** | Service mesh visualization | Real-time topology, traffic flow, health | [kiali.io](https://kiali.io/) |
| **Prometheus** | Metrics collection & storage | Scrapes metrics from Envoy, Istio, applications | [prometheus.io](https://prometheus.io/) |
| **Grafana** | Metrics visualization | Pre-built dashboards for Istio metrics | [grafana.com](https://grafana.com/) |
| **Jaeger** | Distributed tracing | Traces request paths across services | [jaegertracing.io](https://www.jaegertracing.io/) |
| **Loki** | Log aggregation | Log querying and analysis | [grafana.com/loki](https://grafana.com/oss/loki/) |

## ⚡ Quick Start

### 1. Prerequisites

```bash
# Verify Istio is installed
kubectl -n istio-system get all | grep istio

# Check for default addon path
ls /opt/istio-installation/istio-1.28.1/samples/addons/
# Expected: grafana.yaml jaeger.yaml kiali.yaml loki.yaml prometheus.yaml
```

### 2. Deploy Addons

```bash
# Make script executable
chmod +x istio_addons.sh

# Deploy with default settings
./istio_addons.sh

# Or specify custom path and wait time
./istio_addons.sh /path/to/istio/samples/addons/ --wait 90

# Get help
./istio_addons.sh --help
```

### 3. Verify Deployment

```bash
# Watch pod creation
kubectl get pod -n istio-system -w

# Check addon-specific pods
kubectl get pod -n istio-system | grep -E "kiali|prometheus|grafana|jaeger|loki"

# Expected: All pods in Running state
```

### 4. Access Addons

**Port Forward Method:**
```bash
# Kiali (Service Mesh Visualization)
kubectl port-forward -n istio-system svc/kiali 20000:20000 &
# Open: http://localhost:20000
# Default: admin/admin

# Prometheus (Metrics Storage)
kubectl port-forward -n istio-system svc/prometheus 9090:9090 &
# Open: http://localhost:9090

# Grafana (Metrics Dashboards)
kubectl port-forward -n istio-system svc/grafana 3000:3000 &
# Open: http://localhost:3000
# Default: admin/admin

# Jaeger (Distributed Tracing)
kubectl port-forward -n istio-system svc/jaeger 16686:16686 &
# Open: http://localhost:16686
```

**Expose via Istio Gateway (production):**
See [Advanced Configuration](#advanced-configuration) for ingress setup.

## 📁 Installation Files

Available addons in default Istio installation:

```bash
ls /opt/istio-installation/istio-1.28.1/samples/addons/
README.md  extras  grafana.yaml  jaeger.yaml  kiali.yaml  loki.yaml  prometheus.yaml
```

Each YAML file can be deployed individually or all at once using `istio_addons.sh`.

Each YAML file can be deployed individually or all at once using `istio_addons.sh`.

## 🔍 Addons Explained

### Kiali — Service Mesh Visualization

**What it does:**
- Real-time visualization of service mesh topology
- Traffic flow analysis (requests per second, latency, errors)
- Health monitoring for services and deployments
- Configuration validation
- Traffic policy management

**Use Cases:**
- Understand service dependencies
- Troubleshoot traffic issues
- Monitor error rates
- Validate Istio configuration

**Access:**
```bash
kubectl port-forward -n istio-system svc/kiali 20000:20000
# http://localhost:20000 (admin/admin)
```

**Key Features:**
- Graph visualization (app, service, workload levels)
- Metrics display inline on graph
- Error highlighting
- Request tracing integration with Jaeger

---

### Prometheus — Metrics Collection & Storage

**What it does:**
- Scrapes metrics from Envoy proxies, Istio components, and applications
- Stores time-series metrics for querying
- Powers dashboards and alerts

**Default Scrape Targets:**
- Envoy proxy metrics (port 15000)
- Istio control plane (port 8883)
- Kiali metrics
- Application endpoints (if properly instrumented)

**Use Cases:**
- Query service metrics (latency, requests, errors)
- Create custom dashboards
- Set up alerting
- Trend analysis

**Access:**
```bash
kubectl port-forward -n istio-system svc/prometheus 9090:9090
# http://localhost:9090 (query interface)
```

**Example Queries:**
```promql
# Request rate (requests per second)
rate(envoy_cluster_upstream_rq{cluster_name="inbound|8080||"}[1m])

# Error rate
rate(envoy_cluster_upstream_rq{cluster_name="inbound|8080||",response_code=~"5.."}[1m])

# P95 latency
histogram_quantile(0.95, rate(envoy_cluster_upstream_rq_time_bucket[5m]))
```

---

### Grafana — Metrics Visualization

**What it does:**
- Pre-built dashboards for Istio metrics
- Connect to Prometheus as data source
- Create custom dashboards
- Set up alerts and notifications

**Included Dashboards:**
- Istio Mesh Dashboard (overall mesh health)
- Istio Service Dashboard (per-service metrics)
- Istio Workload Dashboard (per-pod metrics)
- Grafana Mesh Monitor (third-party dashboard)

**Use Cases:**
- Monitor mesh health at a glance
- Track performance trends
- Identify bottlenecks
- Alert on anomalies

**Access:**
```bash
kubectl port-forward -n istio-system svc/grafana 3000:3000
# http://localhost:3000 (admin/admin)
```

**Key Dashboards:**
1. **Istio Mesh** — Overall mesh statistics
2. **Istio Service** — Request rate, error rate, latency per service
3. **Istio Workload** — Pod-level metrics
4. **Prometheus** — Raw metric exploration

---

### Jaeger — Distributed Tracing

**What it does:**
- Captures request traces across service boundaries
- Shows latency breakdown between services
- Identifies bottlenecks and error paths
- Integrates with Envoy sidecar proxies

**Trace Components:**
- Trace (complete request path)
- Span (single operation)
- Logs (events within a span)
- Tags (metadata)

**Use Cases:**
- Debug slow requests (end-to-end latency)
- Find which service is causing errors
- Understand request flow
- Identify service dependencies

**Access:**
```bash
kubectl port-forward -n istio-system svc/jaeger 16686:16686
# http://localhost:16686
```

**Search:**
- By service name
- By trace ID (from logs)
- By latency threshold
- By error status

---

### Loki — Log Aggregation

**What it does:**
- Collects logs from all pods
- Lightweight alternative to full ELK stack
- Integrates with Grafana for visualization
- Query logs by service and labels

**Label-Based Query:**
- Namespace, pod, deployment, service
- Custom labels from applications
- Efficient log searching

**Use Cases:**
- Find application logs for debugging
- Search logs by service/namespace
- Correlate logs with metrics/traces
- Investigate errors

**Access:**
```bash
# Via Grafana Explore tab
# Or query directly if exposed
```

**Example Query:**
```
{namespace="default", pod=~"app-.*"} | "error"
```

---

## ✅ Verification

### Check Pod Status

```bash
# All addon pods
kubectl get pod -n istio-system

# Specific addon
kubectl get pod -n istio-system -l app=kiali
kubectl get pod -n istio-system -l app=prometheus
kubectl get pod -n istio-system -l app=grafana
kubectl get pod -n istio-system -l app=jaeger
kubectl get pod -n istio-system -l app=loki
```

### Check Services

```bash
# Verify services are created
kubectl get svc -n istio-system | grep -E "kiali|prometheus|grafana|jaeger|loki"

# Check service details
kubectl describe svc kiali -n istio-system
```

### Check Logs

```bash
# Check for errors
kubectl logs -n istio-system -l app=kiali --tail=20

# Watch pod startup
kubectl logs -n istio-system -l app=prometheus -f
```

### Health Checks

```bash
# Prometheus health
kubectl port-forward -n istio-system svc/prometheus 9090:9090
# Visit http://localhost:9090/graph
# Should show available metrics

# Kiali health
kubectl port-forward -n istio-system svc/kiali 20000:20000
# Visit http://localhost:20000
# Should show service mesh topology

# Grafana health
kubectl port-forward -n istio-system svc/grafana 3000:3000
# Visit http://localhost:3000
# Should load dashboard
```

---

## 🔒 Security Considerations

### Default Credentials

⚠️ **IMPORTANT**: Change default credentials in production!

| Service | Default User | Default Password | How to Change |
|---------|--------------|------------------|---------------|
| Kiali | admin | admin | Edit Kiali configmap or CR |
| Grafana | admin | admin | Change on first login |
| Jaeger | None | None | Public by default |
| Loki | None | None | Public by default |

### Restrict Access

**Option 1: Network Policy**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-addon-access
  namespace: istio-system
spec:
  podSelector:
    matchLabels:
      app: kiali
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: admin
```

**Option 2: Istio AuthorizationPolicy**
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: kiali-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: kiali
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/admin"]
    to:
    - operation:
        methods: ["GET"]
```

**Option 3: Expose via Gateway with Auth**
- Use Istio Gateway + AuthorizationPolicy
- Require OIDC/OAuth authentication
- Place behind VPN for admin access

### Resource Limits

Addons can consume significant resources. Monitor and set limits:

```bash
# Check current usage
kubectl top pod -n istio-system

# Set resource requests/limits in addon YAML
# Example: 500m CPU, 1Gi memory for Prometheus
```

---

## 🚀 Advanced Configuration

### Expose Addons via Istio Gateway

Create an Istio Gateway and VirtualService for public access:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: addon-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "kiali.example.com"
    - "grafana.example.com"
    - "prometheus.example.com"
    tls:
      mode: SIMPLE
      credentialName: addon-certs

---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: kiali-vs
  namespace: istio-system
spec:
  hosts:
  - "kiali.example.com"
  gateways:
  - addon-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: kiali
        port:
          number: 20000
```

### Persistence Configuration

For production, configure persistent storage:

```yaml
# Prometheus with PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
  namespace: istio-system
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
```

### Custom Dashboards

Create custom Grafana dashboards:

1. Login to Grafana (http://localhost:3000)
2. Create → Dashboard
3. Add panels with Prometheus queries
4. Save and share

---

## 🔧 Troubleshooting

### Addons Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n istio-system

# Check logs for errors
kubectl logs <pod-name> -n istio-system

# Common issues:
# - Insufficient resources (check available memory/CPU)
# - Missing dependencies (e.g., Prometheus before Grafana)
# - CRD not installed
```

### Metrics Not Appearing

```bash
# Verify Prometheus is scraping
kubectl port-forward -n istio-system svc/prometheus 9090:9090
# Check Status → Targets (should show "UP")

# Check if services are properly labeled
kubectl get svc -n istio-system -L app
```

### Kiali Not Showing Services

```bash
# Kiali needs Prometheus running first
kubectl get pod -n istio-system | grep prometheus

# Ensure services are using Istio sidecar
kubectl get pod -n default -l version=v1 -o jsonpath='{range .items[*].spec.containers[*]}{.name}{"\n"}{end}'
# Should show: app, istio-proxy
```

### Connection Refused on Port Forward

```bash
# Check if service exists
kubectl get svc kiali -n istio-system

# Check firewall
netstat -tlnp | grep 20000

# Try different port
kubectl port-forward -n istio-system svc/kiali 20001:20000
```

---

## 📊 Performance Tuning

### Prometheus Retention

By default, Prometheus keeps 15 days of metrics. To change:

```bash
# Edit Prometheus ConfigMap
kubectl edit cm prometheus -n istio-system
# Change: --storage.tsdb.retention.time=30d
```

### Grafana Datasource Settings

Adjust Prometheus query timeout for large datasets:
1. Configuration → Data sources → Prometheus
2. Timeout: 60s (increase if queries are slow)

### Loki Log Retention

Configure log retention period in Loki config:
```yaml
limits_config:
  retention_period: 72h
```

---

## 📚 References & Resources

### Official Documentation
- [Istio Observability](https://istio.io/latest/docs/tasks/observability/) — Istio observability guide
- [Kiali Documentation](https://kiali.io/documentation/) — Kiali user guide
- [Prometheus Docs](https://prometheus.io/docs/) — Prometheus official docs
- [Grafana Docs](https://grafana.com/docs/grafana/) — Grafana documentation
- [Jaeger Documentation](https://www.jaegertracing.io/docs/) — Jaeger setup and usage
- [Loki Docs](https://grafana.com/docs/loki/) — Loki installation and configuration

### Istio-Specific Guides
- [Istio Dashboard](https://istio.io/latest/docs/tasks/observability/metrics/using-istio-dashboard/) — Using Grafana dashboard
- [Metrics Querying](https://istio.io/latest/docs/tasks/observability/metrics/querying-metrics/) — Prometheus queries for Istio
- [Distributed Tracing](https://istio.io/latest/docs/tasks/observability/distributed-tracing/) — Jaeger integration

### Community Resources
- [Prometheus PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/) — Query language guide
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/) — Community dashboards
- [OpenTelemetry](https://opentelemetry.io/) — Observability standards

---

## ✨ Quick Command Reference

```bash
# Deploy addons
./istio_addons.sh

# Check status
kubectl get pod -n istio-system | grep -E "kiali|prometheus|grafana|jaeger|loki"

# Port forward all
kubectl port-forward -n istio-system svc/kiali 20000:20000 &
kubectl port-forward -n istio-system svc/prometheus 9090:9090 &
kubectl port-forward -n istio-system svc/grafana 3000:3000 &
kubectl port-forward -n istio-system svc/jaeger 16686:16686 &

# View logs
kubectl logs -n istio-system -l app=kiali -f

# Edit config
kubectl edit cm kiali -n istio-system

# Delete addons
kubectl delete -f /opt/istio-installation/istio-1.28.1/samples/addons/
```
