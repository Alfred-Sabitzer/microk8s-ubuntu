#!/usr/bin/env bash

FILE="$1"

openssl pkcs12 \
    -info \
    -in "$FILE"