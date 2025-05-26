#!/bin/sh
############################################################################################
# Build Go Module
############################################################################################
rm -f ./hello-world
go mod init hello-world
go mod tidy
go mod download
go mod verify
CGO_ENABLED=0
GOOS=linux
go build -a -ldflags '-extldflags "-static"' -o ./hello-world hello-world.go