#!/bin/bash
############################################################################################
# Instance Generator
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition

#######
# This is ubuntu
#######
python3 instancegenerator.py \
    --project=default \
    --profile=default \
    --image="ubuntu" \
    --template_dir=./template \
    --name=demoministandard
python3 instancegenerator.py \
    --project=default \
    --profile=default \
    --image="ubuntu" \
    --template_dir=./template \
    --name=demoreplace

#######
# This is alpine
#######

python3 instancegenerator.py \
    --project=default \
    --profile=infrastructure \
    --image="alpine" \
    --template_dir=./template \
    --name=demoansible
