#!/bin/bash
############################################################################################
#
# Pull image with microk8s
#
############################################################################################
set -euo pipefail
#shopt -o -s xtrace #—Displays each command before it is executed.

sudo microk8s ctr images pull harbor.test.slainte.at/test/dummy@sha256:63c49e1cdae675cf9f93bd95db9625938e49811aec1e28f4b268dd3ab72bc1af --user "robot\$test+k8s:t650sYZpAibJfL4hpyr7b5HrqwVTYOkV"
