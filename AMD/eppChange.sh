#!/bin/bash
eppPreference=/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
choice=""
echo "AMD EPP Changer 1.1"
echo "Available preferences: $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences)"
echo "Current EPP Preference $(cat $eppPreference)"
read -p "Choose an option: " choice
sudo cpupower set --epp $choice
echo "Current EPP Preference $(cat $eppPreference)"
