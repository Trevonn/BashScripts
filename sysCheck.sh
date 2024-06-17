#!/bin/bash

function sysCheck() {
    local cpufreq=/sys/devices/system/cpu/cpu0/cpufreq/
    local gpuLevel=/sys/class/drm/card1/device/power_dpm_force_performance_level
    
    echo
    echo "CPU"
    echo "......................"
    echo "Scaling Governor     : $(cat $cpufreq/scaling_governor)"
    echo "Scaling Driver       : $(cat $cpufreq/scaling_driver)"
    echo "AMD P-State Mode     : $(cat /sys/devices/system/cpu/amd_pstate/status)"
    echo "EPP Preference       : $(if [ -f $cpufreq/energy_performance_preference ]; then cat $cpufreq/energy_performance_preference; else echo 'N/A'; fi)"
    echo "Clocksource          : $(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"
    echo
    echo "GPU"
    echo "......................"
    echo "Mesa                 : $(vulkaninfo | grep driverVersion | awk '{ print $3 }')"
    echo "LLVM                 : $(llvm-config --version)"
    echo "OpenGL               : $(glxinfo | grep 'OpenGL core profile version string' | awk '{ print $6 }')"
    echo "Vulkan               : $(vulkaninfo | grep apiVersion | awk '{ print $3 }')"
    echo "AMD Perf State       : $(cat $gpuLevel)"
    echo
    echo "System"
    echo "......................"
    echo "Kernel               : $(uname -r)"
    echo "glibc                : $(ldd --version | grep ldd | awk '{print $4}')"
    echo "vm.max_map_count     : $(cat /proc/sys/vm/max_map_count)"
    echo "DefaultLimitNOFILE   : $(ulimit -Hn)"
    echo
    echo "Utilities"
    echo "......................"
    echo "MangoHud             : $(if [[ -f /usr/bin/mangohud ]] ; then mangohud --version | cut -c 2- ; else echo 'MangoHud not installed'; fi)"
    echo "Feral GameMode       : $(if [[ -f /usr/bin/gamemoded ]] ; then gamemoded -v | awk '{ print $3 }' | cut -c 2- ; else echo 'Feral GameMode not installed' ; fi )"
}

sysCheck > sysCheck.txt
