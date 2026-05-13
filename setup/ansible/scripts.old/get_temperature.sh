#!/bin/bash
# Liest die Temperatur aus
ansible all -m shell -a 'cat /sys/class/thermal/thermal_zone0/temp '
