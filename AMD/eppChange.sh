#!/bin/bash
local choice=""
echo "AMD EPP Changer 1.0"
echo "Available preferences: $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences)"
read -p "Choose an option: " choice
ls /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference | { 
    while read cpu ; do
        sudo sh -c "echo "$choice" > "$cpu""
    done
}
echo "printing current epp values"
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
