#!/bin/bash
############################################################################################
#
# create a configmap from a directory-contents
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition

# Überprüfen der Parameter
if [ "${1}" = "" ] ;
then
	echo "Usage: $0 Quelle Ziel "
	echo "eg: $0	 /tmp/myconfigfile /tmp/my_configmap.yaml"
	exit -1
fi
if [ "${2}" = "" ] ;
then
	echo "Usage: $0 Quelle Ziel "
	echo "eg: $0	 /tmp/myconfigfile /tmp/my_configmap.yaml"
	exit -1
fi
idir=${1}
ofile=${2}
if [ ! -d "${idir}" ]; then # Das ist kein Verzeichnis
	echo "Usage: $0 Quelle Ziel "
	echo "\"$@\"" "ist kein Verzeichnis"
	exit -1
fi

# Schreiben des Ausgabefiles
exec 4> ${ofile}
echo "---">&4
echo "# \${image}-\${tag}" >&4 
echo "# generiert mit $0 $1 $2" >&4 
echo "apiVersion: v1" >&4 
echo "kind: ConfigMap" >&4 
echo "metadata:" >&4 

string="${ofile}"
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
outname=${keyclean}
echo "  name: ${outname}-cm" >&4 
echo "  namespace: \${namespace}" >&4 

# loop über das Verzeichnis
#echo ${idir}
echo "data: # ${idir}" >&4 
FILES="${idir}/*.conf
${idir}/*.ini
${idir}/*.html
${idir}/*.php
${idir}/*.sh
${idir}/*.txt
${idir}/*.json
${idir}/*.webmanifest"
for filename in $FILES ; do
  if [ -f "${filename}" ]
  then
	string="${filename}"
	#echo "${string}"
	prefix="/"
	suffix=""
	repl=${string%"$prefix"*}
	#echo "${repl}"
	keyn=${string#"$repl$prefix"}
	#echo "${keyn}"
	keyn=${keyn%"$suffix"*}
	#echo "${keyn}"
	keyclean=${keyn//_/$'-'}
	echo "  ${keyn}: |" >&4 
	while read
	do
		echo "    ${REPLY}">&4
	done <  ${filename}
  fi
done
# loop über das Verzeichnis
echo "binaryData: # ${idir}" >&4 
FILES="${idir}/*.asc
${idir}/*.rev
${idir}/*.pem
${idir}/*.crt
${idir}/*.key
${idir}/*.png
${idir}/*.jpg 
${idir}/authorized_keys 
${idir}/*.ico"
for filename in $FILES ; do
  if [ -f "${filename}" ]
  then
	string="${filename}"
	#echo "${string}"
	prefix="/"
	suffix=""
	repl=${string%"$prefix"*}
	#echo "${repl}"
	keyn=${string#"$repl$prefix"}
	#echo "${keyn}"
	keyn=${keyn%"$suffix"*}
	#echo "${keyn}"
	keyclean=${keyn//_/$'-'}
	cat ${filename} | base64 > /tmp/bd.txt
	echo "  ${keyn}: |" >&4 
	while read
	do
		echo "    ${REPLY}">&4
	done <  /tmp/bd.txt
  fi
done
echo "---">&4
exec 4>&-

