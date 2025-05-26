#!/bin/sh
echo "############################################################################################"
echo "#"
echo "# Einfaches Dummy, macht nix "
echo "#"
echo "############################################################################################"
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
while [ true ]
do
	echo "`date` [`hostname`] "
	sleep $((300 + RANDOM % 11));
done
echo "Das wird nie passieren"
