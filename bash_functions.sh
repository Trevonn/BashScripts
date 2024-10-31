#!/bin/bash
# General

mkcd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

nvmeHealth() {
    local option="" 
    read -p "Disk: " option
    sudo nvme smart-log -H /dev/nvme$option
}

resetDevice() {
    local option=""
    local module=""
    echo "Device Reset 1.0"
    echo "1. Bluetooth                   - btusb"
    echo "2. Intel WiFi                  - iwlmvm"
    echo "3. Mediatek WiFi               - mt7921e"
    echo "4. PlayStation 4/5 Controllers - hid_playstation"
    echo "5. PlayStation 3 Controllers   - hid_sony"
    read -p "Option: " option
    case $option in
        1)
            module=btusb ;;
        2)
            module=iwlmvm ;;
        3)
            module=mt7921e ;;
        4)
            module=hid_playstation ;;
        5)
            module=hid_sony ;;
        *)
            echo "Incorrect or no option chosen"
            return
    esac
    echo "Option $module reset"
    sudo rmmod $module && sudo modprobe $module
}

findFiles() {
    find -type f -name "*.$1"
}

findFiles2() {
    find ./ -type f \( -iname \*."$1" -o -iname \*."$2" \)
}

findFolders() {
    find -maxdepth 1 -type d -name "$1*"
}

to7z() {
    7z a -mx9 "${1%.$2}.7z" "$1"
}

toZst() {
    tar -I "zstd --ultra -22 -T$(nproc)" -cf $1.tar.zst $1
}

delete() {
    if [[ -d "$1" ]]
    then
        sudo rm -r "$1"
        echo "Deleting folder $1"
    elif [[ -f "$1" ]]
    then
        sudo rm "$1"
        echo "Deleting file $1"
    else
        echo "$1 not found"
    fi
}

tscCheck() {
    if [[ $(cat /sys/devices/system/clocksource/clocksource0/current_clocksource) == "tsc" ]]
    then
        echo "TSC is active" | systemd-cat -p info
        echo "TSC is active"
    else
        echo "TSC is not active" | systemd-cat -p emerg
        echo "TSC is not active"
    fi
    return
}

clearCacheFiles() {
    find $XDG_CACHE_HOME -type d -name "$1" | while read folder
    do
      find $folder -name "*" -type f -mtime +1 -delete
    done
}

storageCleanup() {
    yay -Scc
    sudo rm -r /var/log/journal/*
    echo "Cleared /var/log/journal"
    sudo rm -rf /var/lib/systemd/coredump/*
    echo "Cleared /var/lib/systemd/coredump"
    find "$XDG_CACHE_HOME" -name "ksycoca6*" -type f -mtime +1 -delete
    find "$XDG_CACHE_HOME/qtshadercache-x86_64-little_endian-lp64/" -name "*" -type f -mtime +1 -delete
    find "$XDG_CACHE_HOME" -name "*.qmlc" -type f -mtime +1 -delete
    find "$XDG_CACHE_HOME" -name "*.jsc" -type f -mtime +1 -delete
    find "$XDG_CACHE_HOME" -name "qqpc_opengl" -type f -mtime +1 -delete
    echo "Cleared various cache files"
}

debugLogs() {
    mkdir debugLogs
    cd debugLogs
    dmesg > dmesg.log
    journalctl -b > journalctl.log
    glxinfo > glxinfo.log
    vulkaninfo > vulkaninfo.log
    lsusb > lsusb.log
    lspci > lspci.log
    sudo fdisk -l > fdisk.log
    cd ../
    zip -9 debugLogs.zip debugLogs/*
    rm -R debugLogs
}

# Media

toFlac() {
    findFiles $1 | parallel ffmpeg -i "{}" -c:a flac -sample_fmt s32 "{.}.flac"
}

flacToOpus() {
    findFiles flac | parallel opusenc --bitrate $1 "{}" "{.}.opus"
}

tagMusic() {
    if [[ "$1" == "title" ]]
    then
        kid3-cli -c "select *.opus" -c "totag '%{title}' 2"
    elif [[ "$1" == "album" ]]
    then
        kid3-cli -c "select *.opus" -c "set Album '$2'"
    else
        echo "Fail"
    fi
}

downloadMusic() {
    yt-dlp --format 251 --extract-audio --audio-format "opus" $1 -o "%(title)s.%(ext)s"
}

mkvDefaultTrack() {
    echo "MKV Default Track Changer 1.0"
    echo "This script lets you change the default track properties in an MKV"
    echo ""
    local trackType=""
    local trackNum=""
    local trackDef=""
    local trackForced=""
    mkvInfo "$file"
    echo "MKV Default Track Selector"
    read -p "Default track type: audio or subtitle (a/s): " trackType
    read -p "Choose a track number: " trackNum
    read -p "Set the track number as default? (0,1): " trackDef
    read -p "Set the track number as forced (0,1) " trackForced
    findFiles mkv | parallel mkvpropedit "{}" --edit track:$trackType$trackNum --set flag-default=$trackDef --set flag-forced=$trackForced
}

toMKV() {
    findFiles $1 | parallel mkvmerge -o "{.}.mkv" "{}"
}

removeTracks() {
# Audio and Subtitle tracks not chosen by $1 and $2 will be removed
    findFiles mkv | parallel mkvmerge -o "Muxed/{}" -a $1 -s $2 "{}"
}

addSubs() {
    findFiles $1 | parallel mkvmerge -o "Muxed/{}" "{}" "{.}".srt
}

toJxl() {
    local type=""
    read -p "Image Type: " type
    echo ".$type images chosen"
    findFiles $type | parallel cjxl "{}" "{.}.jxl"
}

videoState() {
    # $1 The file containing the list of videos
    cat $1 | while read video
    do
#       echo $video
        if [[ -f "$video" ]]
        then
            mv $video $video.bak
            echo "Disabled $video"
        elif [[ -f "$video.bak" ]]
        then
            mv $video.bak $video
            echo "Restored $video"
        else
            echo "Video/s not found"
        fi
    done
}

# Gaming

# Gaming-Wine

wineKill() {
    kill -9 $(ps -ef | grep -E -i "(wine|processid|\.exe)" | awk "{print $2}")
    killall -9 pressure-vessel-adverb
}

downloadDirectX() {
    curl -s https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest | grep -o "https.*zst" | wget -i -
    curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest | grep -om 1 "https.*tar.gz" | wget -i -
}

dx11() {
    echo "Installing DXVK (DirectX 8,9,10,11)"
    $HOME/Sync/Gaming/DXVK/setup_dxvk.sh install --symlink
}

dx12() {
    echo "Installing VKD3D-Proton (DirectX 12)"
    $HOME/Sync/Gaming/VKD3D-Proton/setup_vkd3d_proton.sh install --symlink
}

dxSetup() {
    dx11
    dx12
}

# Gaming-Emulation

crom() {
    case $1 in
    "chdDVD")
        findFiles2 iso bin | parallel chdman createdvd -f -i "{}" -o "{.}.chd -c zstd" ;;
    "chdCD")
        findFiles cue | parallel chdman createcd -f -i "{}" -o "{.}.chd" ;;
    *)
        echo "Incorrect or no option chosen"
    esac
}

crom7z() {
    findFiles $1 | parallel --bar 7z a -mx9 "{.}.7z" "{}"

}

reCrom() {
    ark --batch --autodestination *.7z
    mvrom $1
}

mvrom() {
    local type="$1"
    local dest=""
    case $1 in
        "nes")
            crom7z $type
            type="7z"
            dest="$HOME/Games/Emulation/ROMs/Nintendo/NES" ;;
        "n64")
            crom7z $type
            type="7z"
            dest="$HOME/Games/Emulation/ROMs/Nintendo/N64" ;;
        "gba")
            crom7z $type
            type="7z"
            dest="$HOME/Games/Emulation/ROMs/Nintendo/GBA" ;;
        "nds")
            crom7z $type
            type="7z"
            dest="$HOME/Games/Emulation/ROMs/Nintendo/DS" ;;
        "3ds")
            dest="$HOME/Games/Emulation/ROMs/Nintendo/3DS" ;;
        "switch")
            type="nsp"
            dest="$HOME/Games/Emulation/ROMs/Nintendo/Switch" ;;
        "ps1")
            dest="$HOME/Games/Emulation/ROMs/Sony/PS1"
            type="chdCD"
            crom $type
            type="chd" ;;
        "ps2")
            dest="$HOME/Games/Emulation/ROMs/Sony/PS2"
            type="chdDVD"
            crom $type
            type="chd" ;;
        "psp")
            dest="$HOME/Games/Emulation/ROMs/Sony/PSP"
            type="chdDVD"
            crom $type
            type="chd" ;;
        *)
            echo "Choose a file type!"
            echo "n64    - Nintendo 64"
            echo "gba    - GameBoy Advance"
            echo "nds    - Nintendo DS"
            echo "3ds    - Nintendo 3DS"
            echo "switch - Nintendo Switch"
            echo "ps1    - PlayStation 1"
            echo "ps2    - PlayStation 2"
            echo "psp    - PlayStation Portable"
            return
    esac
    echo "Moving $1 files to $dest"
    mv *.$type "$dest"
}

# Gaming-Misc

changeGPUState() {
    local gpuLevel=/sys/class/drm/card1/device/power_dpm_force_performance_level
    echo "Current GPU Level: $(cat $gpuLevel)"
    echo "Setting GPU Level to $1"
    sudo sh -c "echo $1 > $gpuLevel"
    echo "Current GPU Level: $(cat $gpuLevel)"
}

# Pi

piBackupSettings() {
    local backupFile="/srv/nfs/Backup/Linux/Raspberry Pi/Raspberry Pi Settings - $(date +"%Y-%m-%d").tar.zst"
    local targets="/home/pi/.profile /home/pi/.bashrc /home/pi/.ssh/authorized_keys /etc/samba /etc/fstab /home/pi/.local/state/syncthing"
    sudo tar -P -I "zstd --ultra -22 -T$(nproc)" -cf "$backupFile" $targets
}

jellyfinBackup() {
    local backupFile="/srv/nfs/Backup/Linux/Raspberry Pi/Jellyfin Backup - $(date +"%Y-%m-%d").tar"
    local targets="/var/lib/jellyfin /etc/jellyfin"
    sudo tar -P -cf "$backupFile" $targets
}

restoreTar() {
    local backupFile=""
    ls -l *.{tar,tar.zst}
    read -p "Which tar file would you like to restore: " backupFile
    sudo tar -P -xf "$backupFile"
}

# Git

buildMesa() {
    local oldLocation=$PWD
    cd "$HOME/Git/mesa"
    git pull
    git status
    time ninja -C build64/ install
    time ninja -C build32/ install
    cd $oldLocation
    rm -rf $HOME/.cache/mesa_shader_cache_sf
}

configureMesa() {
    local oldLocation=$PWD
    local option=""
    local mesaSync="$HOME/Sync/Gaming/Mesa"
    echo "Mesa Configurator 1.0"
    echo "1: RADV"
    echo "2: RADV+Zink"
    echo "3: RADV+Zink+ACO"
    read -p "Choose an option: " option
    cd "$HOME/Git/mesa"
    case $option in
    1)
        meson setup --reconfigure build64 --libdir lib64 --prefix $mesaSync -Dbuildtype=release -Dgallium-drivers= -Dvulkan-drivers=amd -Dllvm=disabled
        meson setup --reconfigure build32 --cross-file gcc-i686 --libdir lib --prefix $mesaSync -Dgallium-drivers= -Dvulkan-drivers=amd -Dllvm=disabled -Dbuildtype=release
        echo "Configured for RADV" ;;
    2)
        meson setup --reconfigure build64 --libdir lib64 --prefix $mesaSync -Dbuildtype=release -Dgallium-drivers=zink -Dvulkan-drivers=amd -Dllvm=disabled
        meson setup --reconfigure build32 --cross-file gcc-i686 --libdir lib --prefix $mesaSync -Dgallium-drivers=zink -Dvulkan-drivers=amd -Dllvm=disabled -Dbuildtype=release
        rm -rf $mesaSync/*
        echo "Configured for RADV+Zink" ;;
    3)        
        meson setup --reconfigure build64 --libdir lib64 --prefix $mesaSync -Dbuildtype=release -Dgallium-drivers=radeonsi,zink -Dvulkan-drivers=amd -Dllvm=disabled
        meson setup --reconfigure build32 --cross-file gcc-i686 --libdir lib --prefix $mesaSync -Dgallium-drivers=radeonsi,zink -Dvulkan-drivers=amd -Dllvm=disabled -Dbuildtype=release
        rm -rf $mesaSync/* ;;
    *)
        echo "Incorrect or no option chosen"
    esac
    cd $oldLocation
}

# Misc

buildLinuxTSC() {
    local patches="$HOME/Sync/Config/Kernel/"
    local kernel=""
    echo "1: linux"
    echo "2: linux-lts"
    read -p "Which kernel would you like to build? " kernel
    case $kernel in
    1)
        kernel="linux" ;;
    2)
        kernel="linux-lts" ;;
    *)
        echo "Incorrect or no option chosen"
        return
    esac
    pkgctl repo clone --protocol=https $kernel
    cd $kernel
    cp $patches/tsc.patch tsc.patch
    patch -i $patches/$kernel.patch PKGBUILD
    time makepkg --syncdeps --skipinteg
}

printAfter() {
    string=$1
    searchstring="$2"
    result=${string#*$searchstring}
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
    echo "System Check V2.01"
    echo
    echo "System"
    echo "......................"
    echo "Kernel               : $(uname -r)"
    echo "glibc                : $(ldd --version | grep ldd | awk '{print $4}')"
    echo "vm.max_map_count     : $(cat /proc/sys/vm/max_map_count)"
    echo "DefaultLimitNOFILE   : $(ulimit -Hn)"
    echo "Steam udev rules     : $(isInstalled /usr/lib/udev/rules.d/70-steam-input.rules)"
    echo
    cpuCheck
    echo
    gpuCheck
    echo
    utilitiesCheck
}

cpuCheck() {
    local cpufreq=/sys/devices/system/cpu/cpu0/cpufreq/
    local turboBoost="$(if [[ $(cat $cpufreq/boost) == 1 ]]; then echo "On"; else echo "Off"; fi)"
    echo "CPU"
    echo "......................"
    echo "Scaling Governor     : $(cat $cpufreq/scaling_governor)"
    echo "Scaling Driver       : $(cat $cpufreq/scaling_driver)"
    echo "Turbo Boost          : $turboBoost"
    echo "AMD P-State Mode     : $(cat /sys/devices/system/cpu/amd_pstate/status)"
    echo "EPP Preference       : $(if [ -f $cpufreq/energy_performance_preference ]; then cat $cpufreq/energy_performance_preference; else echo "N/A"; fi)"
    echo "Clocksource          : $(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"
}

gpuCheck() {
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

utilitiesCheck() {
    echo "Utilities"
    echo "......................"
    echo "MangoHud             : $(if [[ -f /usr/bin/mangohud ]]; then mangohud --version | cut -c 2-; else echo "Not installed"; fi)"
    echo "Feral GameMode       : $(if [[ -f /usr/bin/gamemoded ]]; then gamemoded -v | awk '{ print $3 }' | cut -c 2-; else echo "Not installed"; fi )"
    echo "Gamescope            : $(isInstalled /usr/bin/gamescope)"
}


test_amd_s2idle() {
    mkcd amd_s2idle
    wget https://gitlab.freedesktop.org/drm/amd/-/raw/master/scripts/amd_s2idle.py
    sudo python amd_s2idle.py
}
