#!/bin/bash

printAfter() {
    local string=$1
    local searchstring="$2"
    local result=${string#*$searchstring}
    echo $result
}

isInstalled() {
    if [[ -f $1 ]]
    then
        echo "Installed"
    else
        echo "Not installed";
    fi
}

sysCheck() {
    local kernelVersion=$(uname -r)
    local glibcVersion=$(ldd --version | grep ldd | awk '{print $4}')
    local maxMapCount=$(cat /proc/sys/vm/max_map_count)
    local limitNOFILE=$(ulimit -Hn)
    local steamUdevRules=$(isInstalled /usr/lib/udev/rules.d/70-steam-input.rules)
    local cpufreq=/sys/devices/system/cpu/cpu0/cpufreq/
    local scaleGov=$(cat $cpufreq/scaling_governor)
    local scaleDriver=$(cat $cpufreq/scaling_driver)
    local turboBoost="$(if [[ $(cat $cpufreq/boost) == 1 ]]; then echo "On"; else echo "Off"; fi)"
    local amdPstateMode=$(cat /sys/devices/system/cpu/amd_pstate/status)
    local eppPref="$(if [ -f $cpufreq/energy_performance_preference ]; then cat $cpufreq/energy_performance_preference; else echo "N/A"; fi)"
    local clocksource="$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"
    local gpuLevel=$(cat /sys/class/drm/card1/device/power_dpm_force_performance_level)
    local gpuName=$(printAfter "$(DRI_PRIME=1! vulkaninfo --summary | grep -m 1 "deviceName")" "= ")
    local gpuVram=$(DRI_PRIME=1! glxinfo -B | grep "Dedicated video memory:" | awk 'NR==1 { print $4 }')
    local mesaVersion=$(vulkaninfo | grep driverVersion | awk 'NR==1 { print $3 }')
    local llvmVersion=$(llvm-config --version)
    local openglVersion=$(glxinfo | grep "OpenGL core profile version string" | awk '{ print $6 }')
    local vulkanVersion=$(vulkaninfo | grep apiVersion | awk 'NR==1 { print $3 }')
    local mangohudCheck=$(if [[ -f /usr/bin/mangohud ]]; then mangohud --version | cut -c 2-; else echo "Not installed"; fi)
    local gamemodeCheck=$(if [[ -f /usr/bin/gamemoded ]]; then gamemoded -v | awk '{ print $3 }' | cut -c 2-; else echo "Not installed"; fi )
    local gamescopeCheck=$(isInstalled /usr/bin/gamescope)
    
    echo "System Check V2.11"
    echo
    echo "System"
    echo "......................"
    echo "Kernel               : $kernelVersion"
    echo "glibc                : $glibcVersion"
    echo "vm.max_map_count     : $maxMapCount"
    echo "DefaultLimitNOFILE   : $limitNOFILE"
    echo "Steam udev rules     : $steamUdevRules"
    echo
    echo "CPU"
    echo "......................"
    echo "Scaling Governor     : $scaleGov"
    echo "Scaling Driver       : $scaleDriver"
    echo "Turbo Boost          : $turboBoost"
    echo "AMD P-State Mode     : $amdPstateMode"
    echo "EPP Preference       : $eppPref"
    echo "Clocksource          : $clocksource"
    echo
    echo "GPU"
    echo "......................"
    echo "Name                 : $gpuName"
    echo "VRAM                 : $gpuVram MB"
    echo "Mesa                 : $mesaVersion"
    echo "LLVM                 : $llvmVersion"
    echo "OpenGL               : $openglVersion"
    echo "Vulkan               : $vulkanVersion"
    echo "AMDGPU Perf Level    : $gpuLevel"
    echo
    echo "Utilities"
    echo "......................"
    echo "MangoHud             : $mangohudCheck"
    echo "Feral GameMode       : $gamemodeCheck"
    echo "Gamescope            : $gamescopeCheck"
}

sysCheck
