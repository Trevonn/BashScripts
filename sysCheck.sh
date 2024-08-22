#!/bin/bash

function printAfter() {
    string=$1
    searchstring="$2"
    result=${string#*$searchstring}
    echo $result
}

function isInstalled() {
    if [[ -f $1 ]]
    then
        echo "Installed"
    else
        echo "Not installed";
    fi
}

function cpuCheck() {
    local cpufreq=/sys/devices/system/cpu/cpu0/cpufreq/
    echo "CPU"
    echo "......................"
    echo "Scaling Governor     : $(cat $cpufreq/scaling_governor)"
    echo "Scaling Driver       : $(cat $cpufreq/scaling_driver)"
    echo "AMD P-State Mode     : $(cat /sys/devices/system/cpu/amd_pstate/status)"
    echo "EPP Preference       : $(if [ -f $cpufreq/energy_performance_preference ]; then cat $cpufreq/energy_performance_preference; else echo "N/A"; fi)"
    echo "Clocksource          : $(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"
}

function gpuCheck() {
    local gpuLevel=/sys/class/drm/card1/device/power_dpm_force_performance_level
    echo "GPU"
    echo "......................"
    echo "Name                 : $(printAfter "$(DRI_PRIME=1! vulkaninfo --summary | grep -m 1 "deviceName")" "= ")"
    echo "VRAM                 : $(DRI_PRIME=1! glxinfo -B | grep "Dedicated video memory:" | awk 'NR==1 { print $4 }') MB"
    echo "Mesa                 : $(vulkaninfo | grep driverVersion | awk 'NR==1 { print $3 }')"
    echo "LLVM                 : $(llvm-config --version)"
    echo "OpenGL               : $(glxinfo | grep "OpenGL core profile version string" | awk '{ print $6 }')"
    echo "Vulkan               : $(vulkaninfo | grep apiVersion | awk 'NR==1 { print $3 }')"
    echo "AMDGPU Perf Level    : $(cat $gpuLevel)"
}

function utilitiesCheck() {
    echo "Utilities"
    echo "......................"
    echo "MangoHud             : $(if [[ -f /usr/bin/mangohud ]]; then mangohud --version | cut -c 2-; else echo "Not installed"; fi)"
    echo "Feral GameMode       : $(if [[ -f /usr/bin/gamemoded ]]; then gamemoded -v | awk '{ print $3 }' | cut -c 2-; else echo "Not installed"; fi )"
    echo "Gamescope            : $(isInstalled /usr/bin/gamescope)"
    echo "Steam udev rules     : $(isInstalled /usr/lib/udev/rules.d/70-steam-input.rules)"
}

function sysCheck() {
    echo "System Check V2.00"
    echo
    echo "System"
    echo "......................"
    echo "Kernel               : $(uname -r)"
    echo "glibc                : $(ldd --version | grep ldd | awk '{print $4}')"
    echo "vm.max_map_count     : $(cat /proc/sys/vm/max_map_count)"
    echo "DefaultLimitNOFILE   : $(ulimit -Hn)"
    echo
    cpuCheck
    echo
    gpuCheck
    echo
    utilitiesCheck
}

sysCheck > sysCheck.txt
