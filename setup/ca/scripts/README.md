# Certificates Examples

This is intended to create certificates outside of Kubernetes.

## Usage of cert-manager

you will find a example for a client-certificate

## Verification of certifcates

```bash
./inspect-cert.sh pki/issued/api.example.com/api.example.com.crt.pem

./inspect-p12.sh pki/issued/api.example.com/api.example.com.p12

./verify-cert.sh pki/issued/api.example.com/api.example.com.crt.pem
```

## Algorithm

For 2026, the answer depends on compatibility vs. security vs. performance. There isn't a single "best" algorithm; different use cases favor different choices.

| Algorithm | Security | Performance | Compatibility | Recommended |
|-----------|----------|-------------|---------------|-------------|
| RSA-2048 | Good | Slow | Excellent | Legacy only |
| RSA-3072 | Very Good | Slow | Excellent | Good default if compatibility matters |
| RSA-4096 | Excellent | Slower | Excellent | High-security environments |
| ECDSA P-256 (prime256v1) | Excellent | Very Fast | Excellent | Best general-purpose choice |
| ECDSA P-384 (secp384r1) | Excellent | Fast | Very Good | High-security TLS |
| Ed25519 | Excellent | Extremely Fast | Good | Best for modern systems |
| Ed448 | Outstanding | Moderate | Limited | Specialized use |

## Certificate Lifetime

Current best practice is to keep end-entity certificates relatively short-lived:

Server certificates: 90–397 days is common on the public web, while internal PKIs often use 180–365 days.
Client certificates: 180–365 days, depending on your rotation process.
Intermediate CAs: 5–10 years.
Root CAs: 10–20 years (or longer in tightly controlled environments).

Shorter lifetimes reduce the impact of key compromise and encourage regular key rotation.

## Hash Algorithms

| Component         | Algorithm     | Hash                                                                |
|-------------------|---------------|---------------------------------------------------------------------|
| Root CA           | ECDSA P-384   | SHA-384                                                             |
| Intermediate CA   | ECDSA P-384   | SHA-384                                                             |
| Server            | ECDSA P-256   | SHA-256                                                             |
| Client (mTLS)     | ECDSA P-256   | SHA-256                                                             |
| Generic           | ECDSA P-256   | SHA-256                                                             |
| Compatibility mode| RSA-3072      | SHA-256                                                             |
| Modern mode       | Ed25519       | (Ed25519 has its own integrated signature scheme; no separate hash)  |


That gives excellent interoperability today while also allowing a "modern" profile for environments where Ed25519 is fully supported.