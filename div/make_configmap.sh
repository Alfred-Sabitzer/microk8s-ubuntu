#!/bin/bash
############################################################################################
#
# create a configmap from a file
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition

# Überprüfen der Parameter
if [ "${1}" = "" ] ;
then
	echo "Usage: $0 Quelle Ziel "
	echo "eg: $0	 /etc/ssh/sshd_config /tmp/my_configmap.yaml"
	exit -1
fi
if [ "${2}" = "" ] ;
then
	echo "Usage: $0 Quelle Ziel "
	echo "eg: $0	 /etc/ssh/sshd_config /tmp/my_configmap.yaml"
	exit -1
fi
ifile=${1}
ofile=${2}
if [ ! -f "${ifile}" ]; then # Das ist keine Datei
	echo "Usage: $0 Quelle Ziel "
	echo "\"$@\"" "ist keine Datei"
	exit -1
fi
string="${ifile}"
#echo "${string}"
prefix="/"
suffix="."
repl=${string%"$prefix"*}
#echo "${repl}"
keyn=${string#"$repl$prefix"}
#echo "${keyn}"
keyn=${keyn%"$suffix"*}
#echo "${keyn}"
keyclean=${keyn//_/$'-'}
# Schreiben des Ausgabefiles
exec 4> ${ofile}
echo "---">&4
echo "# \${image}-\${tag}" >&4 
echo "# generiert mit $0 $1 $2" >&4 
echo "apiVersion: v1" >&4 
echo "kind: ConfigMap" >&4 
echo "metadata:" >&4 
echo "  name: \${image}-${keyclean}-cm" >&4 
echo "data: # ${ifile}" >&4 
echo "  ${keyn}: |" >&4 

while read line
do
	echo "    ${line}">&4
done <  ${ifile}
echo "---">&4

exec 4>&-

