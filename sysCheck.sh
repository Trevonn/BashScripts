#!/bin/bash

isInstalled() {
    if [[ -f $1 ]]
    then
        echo "Installed"
    else
        echo "Not installed";
    fi
}

sysInfoGet() {
    cpufreq=/sys/devices/system/cpu/cpu0/cpufreq/
    kernelVersion=$(uname -r)
    glibcVersion=$(ldd --version | grep ldd | awk '{print $4}')
    maxMapCount=$(cat /proc/sys/vm/max_map_count)
    limitNOFILE=$(ulimit -Hn)
    steamUdevRules=$(isInstalled /usr/lib/udev/rules.d/60-steam-input.rules)
    ramQty="$(free -g | grep "Mem:" | awk '{print $ 2}') GB"
    cpuName="$(lscpu | grep 'Model name' | cut -f 2 -d ":" | awk '{$1=$1}1')"
    cpuTemp="$(sensors | grep Tctl | grep -Po '\+\K.*')"
    cpuThreads="$(lscpu | grep -m 1 "CPU(s)" | awk '{print $2}')"
    cpuCores="$(lscpu | grep "Core(s) per socket:" | awk '{print $4}') ($cpuThreads Threads)"
    scaleGov=$(cat $cpufreq/scaling_governor)
    scaleDriver=$(cat $cpufreq/scaling_driver)
    turboBoost="$(if [[ $(cat $cpufreq/boost) == 1 ]]; then echo "On"; else echo "Off"; fi)"
    amdPstateMode=$(cat /sys/devices/system/cpu/amd_pstate/status)
    eppPref="$(if [ -f $cpufreq/energy_performance_preference ]; then cat $cpufreq/energy_performance_preference; else echo "N/A"; fi)"
    clocksource="$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"
    gpuLevel=$(cat /sys/class/drm/card1/device/power_dpm_force_performance_level)
    gpuName=$(DRI_PRIME=1! vulkaninfo --summary | grep "deviceName" | grep -Po '= \K.*')
    gpuVram="$(DRI_PRIME=1! glxinfo -B | grep "Dedicated video memory:" | awk 'NR==1 { print $4 }') MB"
    mesaVersion=$(vulkaninfo | grep driverVersion | awk 'NR==1 { print $3 }')
    llvmVersion=$(llvm-config --version)
    openglVersion=$(glxinfo | grep "OpenGL core profile version string" | awk '{ print $6 }')
    vulkanVersion=$(vulkaninfo | grep apiVersion | awk 'NR==1 { print $3 }')
    mangohudCheck=$(if [[ -f /usr/bin/mangohud ]]; then mangohud --version | grep -Po 'v\K.*'; else echo "Not installed"; fi)
    gamemodeCheck=$(if [[ -f /usr/bin/gamemoded ]]; then gamemoded -v | awk '{ print $3 }' | cut -c 2-; else echo "Not installed"; fi )
    gamescopeCheck=$(isInstalled /usr/bin/gamescope)
}

sysCheck() {
    sysInfoGet
    echo "System Check V2.2"
    echo
    echo "System"
    echo "......................"
    echo "Kernel               : $kernelVersion"
    echo "glibc                : $glibcVersion"
    echo "LLVM                 : $llvmVersion"
    echo "vm.max_map_count     : $maxMapCount"
    echo "DefaultLimitNOFILE   : $limitNOFILE"
    echo "RAM                  : $ramQty"
    echo
    echo "CPU"
    echo "......................"
    echo "Name                 : $cpuName"
    echo "Temperature          : $cpuTemp"
    echo "Cores                : $cpuCores"
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
    echo "VRAM                 : $gpuVram"
    echo "Mesa                 : $mesaVersion"
    echo "OpenGL               : $openglVersion"
    echo "Vulkan               : $vulkanVersion"
    echo "AMDGPU Power State   : $gpuLevel"
    echo
    echo "Misc"
    echo "......................"
    echo "MangoHud             : $mangohudCheck"
    echo "Feral GameMode       : $gamemodeCheck"
    echo "Gamescope            : $gamescopeCheck"
    echo "Steam udev rules     : $steamUdevRules"

}

dxvkTemplate() {
    sysInfoGet
    local protonLocation=$HOME/"Games/Steam/steamapps/common/Proton - Experimental"
    local protonVersion="proton-$(cat "$protonLocation/version" | awk '{print $2}')"
    local dxvkVersion="$(cat "$protonLocation/files/lib/wine/dxvk/version" | awk '{print $3}')"
    local vkd3dVersion="$(cat "$protonLocation/files/lib/wine/vkd3d-proton/version" | awk '{print $3}')"
    echo "### System Information"
    echo "- GPU            : $gpuName"
    echo "- Driver         : Mesa $mesaVersion"
    echo "- Wine           : $protonVersion"
    echo "- DXVK           : $dxvkVersion"
    echo "- VKD3D-Proton   : $vkd3dVersion"
    echo "- Kernel         : $kernelVersion"
    echo "- CPU            : $cpuName"
    echo "- RAM            : $ramQty"
    echo "- VRAM           : $gpuVram"
}
