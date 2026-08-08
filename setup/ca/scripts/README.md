# `setup/ca/scripts`

This directory contains helper scripts for certificate inspection, extraction, and local certificate creation.

> These scripts are intended as lightweight tools for working with CA material and issued certificates outside of Kubernetes.

## Prerequisites

- `kubectl` access to the target cluster.
- A rooted CA available under `~/pki/root/ca.crt` and `~/pki/root/ca.key` for `create_client_certificate.sh`.
- `openssl` installed.

## Scripts

### `create_client_certificate.sh`

Generate a certificate signed by `~/pki/root/ca.crt` and `~/pki/root/ca.key`.

Usage:

```bash
chmod +x create_client_certificate.sh
./create_client_certificate.sh NAME [server|client|both] [PASSWORD] [EMAIL] [K8S_ENVIRONMENT]
```

Example:

```bash
./create_client_certificate.sh api.example.com server changeit admin@example.com example
```

Files are written to `~/pki/issued/NAME/`.

### `get_alfred-slainte-at-tls.sh`

Extract a certificate secret from Kubernetes and export it locally.

Usage:

```bash
chmod +x get_alfred-slainte-at-tls.sh
./get_alfred-slainte-at-tls.sh [SECRET_NAME] [NAMESPACE] [PASSWORD] [OUTPUT_DIR]
```

Default values:

- `SECRET_NAME=alfred-slainte-at-tls`
- `NAMESPACE=istio-system`
- `PASSWORD=changeit`
- `OUTPUT_DIR=~/pki/SECRET_NAME`

### `inspect_cert.sh`

Inspect a PEM certificate.

Usage:

```bash
chmod +x inspect_cert.sh
./inspect_cert.sh path/to/certificate.pem
```

### `inspect_p12.sh`

Inspect a PKCS#12 bundle.

Usage:

```bash
chmod +x inspect_p12.sh
./inspect_p12.sh path/to/certificate.p12
```

### `verify_cert.sh`

Verify a certificate using either a user-provided CA bundle or the system trust store.

Usage:

```bash
chmod +x verify_cert.sh
./verify_cert.sh path/to/certificate.pem [ca-file.pem]
```

If `ca-file.pem` is omitted, the script attempts to verify against the system CA bundle.

## Notes

- `setup/ca/archive` contains older or experimental scripts and manifests.
- The active supported workflow is under `setup/ca/` and `setup/ca/scripts/`.
