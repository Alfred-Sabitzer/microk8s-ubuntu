#!/bin/bash
############################################################################################
# installation of periodic jobs
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
#

cat << EOF > /home/ansible/ansible/log/crontab.txt
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
# Edit this file to introduce tasks to be run by cron.
# 
# m h  dom mon dow   command
#string		meaning
#@reboot	Run once, at startup.
#@yearly	Run once a year, "0 0 1 1 *".
#@annually	same as @yearly)
#@monthly	Run once a month, "0 0 1 * *".
#@weekly	Run once a week, "0 0 * * 0".
#@daily		Run once a day, "0 0 * * *".
#@midnight	(same as @daily)
#@hourly	Run once an hour, "0 * * * *". 
@hourly	date > /home/ansible/ansible/log/cron.out > /dev/null 2>&1
@hourly /home/ansible/scripts/create_hosts_file.sh > /dev/null 2>&1
EOF
crontab /home/ansible/ansible/log/crontab.txt
#