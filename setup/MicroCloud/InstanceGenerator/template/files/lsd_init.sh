#!/bin/bash
############################################################################################
# Initialize Linux Standard Directory structure
# https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition

move_dir() {             
    echo "$0 will move '${1}' to /data and create a symlink";

    if [ -d /data/${1} ]; then
        echo "/data/${1} exists"
    else
        echo "/data/${1} does not exist - creating it"
        mv -f ${1} /data/${1} || true
    fi

    if [ -d /${1} ]; then
        echo "/${1} exists - removing it"
        mv -f ${1} /${1}_backup || true
    fi
    if [ -L /${1} ]; then
        echo "/${1} is already a symlink"
    else
        echo "/${1} is not a symlink - creating it"
        ln -s /data/${1} /${1}
    fi
}   

move_dir home
move_dir var
move_dir tmp

echo "Directories moved"
