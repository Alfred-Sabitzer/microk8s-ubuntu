# Bookinfo Demo Application (Istio sample) - Fault injection

## Purpose

test out abilities of istio.
**We will consequently use the istio-api. The Kubernetes api does still not provide all neede features regarding security**

## References
- [Istio Bookinfo Fault Injection](https://istio.io/latest/docs/tasks/traffic-management/fault-injection/)

## Security notes
- These manifests use default container images from istio.io.
- For production, audit and sign container images.
- Ensure NetworkPolicy and AuthorizationPolicy are in place to restrict inter-service traffic.
- Keep secrets/API keys out of manifests; use Kubernetes Secrets or external secret management.
