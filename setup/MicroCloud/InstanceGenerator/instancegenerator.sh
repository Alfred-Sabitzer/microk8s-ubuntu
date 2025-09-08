#!/bin/bash
############################################################################################
# Instance Generator
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
python3 instancegenerator.py \
    --project=default \
    --profile=default \
    --image="ubuntu 24.04 LTS amd64 (minimal release) (20250727)" \
    --type=standard \
    --template_dir=./template \
    --name=demoministandard
python3 instancegenerator.py \
    --project=default \
    --profile=default \
    --image="ubuntu 24.04 LTS amd64 (minimal release) (20250727)" \
    --type=minimal \
    --template_dir=./template \
    --name=demominiminimal
python3 instancegenerator.py \
    --project=default \
    --profile=default \
    --image="ubuntu 24.04 LTS amd64 (release) (20250805)" \
    --type=minimal \
    --template_dir=./template \
    --name=demominimal
python3 instancegenerator.py \
    --project=default \
    --profile=default \
    --image="ubuntu 24.04 LTS amd64 (release) (20250805)" \
    --type=standard \
    --template_dir=./template \
    --name=demostandard
python3 instancegenerator.py \
    --project=default \
    --profile=default \
    --image="Alpine edge amd64 (20250908_0051)" \
    --type=standard_alpine \
    --template_dir=./template \
    --name=demoalpinestandard
    



    