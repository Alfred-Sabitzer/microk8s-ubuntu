#!/bin/bash
############################################################################################
# Build Go Module
############################################################################################
#shopt -o -s errexit	#—Terminates  the shell	script if a	command	returns	an error code.
shopt -o -s xtrace	#—Displays each	command	before it’s	executed.
shopt -o -s nounset	#-No Variables without definition
shopt -s dotglob # Use shopt -u dotglob to exclude hidden directories
IFS="
"
go mod init goencrypt
go get golang.org/x/crypto/openpgp
go get github.com/alecthomas/kingpin/v2
go mod tidy
go mod download
go mod verify
CGO_ENABLED=0
GOOS=linux
go build -a -ldflags '-extldflags "-static"' -o goencrypt main.go