#!/bin/sh
############################################################################################
# Build Go Module
############################################################################################
rm -f ./gpgservice
go mod init gpgservice
go mod tidy
go mod download
go mod verify
CGO_ENABLED=0
GOOS=linux
go build -a -ldflags '-extldflags "-static"' -o ./gpgservice main.go