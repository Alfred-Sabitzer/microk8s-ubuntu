#!/usr/bin/env bash

CERT="$1"

openssl verify \
    -CAfile pki/intermediate/chain.pem \
    "$CERT"