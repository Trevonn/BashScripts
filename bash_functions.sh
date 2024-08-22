# General

function bakup() {
    mv $1 $1.bak
}

function rstore() {
    mv $1.bak $1
}

function nvmeHealth() {
    local option="" 
    read -p "Disk: " option
    sudo nvme smart-log -H /dev/nvme$option
}

function resetDevice() {
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

function sdLoop() {
    local sdService=$1
    local sdCmd=""
    echo "Systemd Loop V1.1"
    echo
    echo "$sdService chosen"
    systemctl status $1
    echo
    echo " 1: Status"
    echo " 2: Restart"
    echo " 3: Enable"
    echo " 4: Disable"
    echo " 5: Stop"
    echo " 6: Start"
    echo " 7: Mask"
    echo " 8: Unmask"
    echo " 9: dameon-reload"
    echo "10: Exit"
    echo
    read -p "Choose an option: " sdCmd
    case $sdCmd in
    1)
        systemctl status $1
        sdLoop $1 ;;
    2)
        systemctl restart $1
        sdLoop $1 ;;
    3)
        systemctl enable $1
        sdLoop $1 ;;
    4)
        systemctl disable $1
        sdLoop $1 ;;
    5)
        systemctl stop $1
        sdLoop $1 ;;
    6)
        systemctl daemon-reload
        systemctl start $1
        sdLoop $1 ;;
    7)
        systemctl mask $1
        sdLoop $1 ;;
    8)
        systemctl unmask $1
        sdLoop $1 ;;
    9)
        systemctl daemon-reload
        sdLoop $1 ;;
    10)
        echo "Exiting" ;;
    *)
        return
    esac
}

function mkcd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

function findFiles() {
    find -type f -name "*.$1"
}

function findFiles2() {
    find ./ -type f \( -iname \*."$1" -o -iname \*."$2" \)
}

function findFolders() {
    find -maxdepth 1 -type d -name "$1*"
}

function to7z() {
    7z a -mx9 "${1%.$2}.7z" "$1"
}

function toZstFolder() {
    findFolders $1 | {
        while read file ; do
            tar -I "zstd --ultra -22" -cf $file.tar.zst $file
        done
    }
}

function to7zFolder() {
    findFolders $1 | {
        while read file ; do
            7z a -mx9 "$file.7z" "$file" -p $2
        done
    }
}

function delete() {
    if [[ -d "$1" ]]
    then
        sudo rm -rf "$1"
        echo "Deleting folder $1"
    elif [[ -f "$1" ]]
    then
        sudo rm -f "$1"
        echo "Deleting file $1"
    else
        echo "$1 not found"
    fi
}

function folderEmptyDelete() {
    if [[ -z "$(ls -A $1)" ]]
    then
        echo "$1 is empty"
    else
        sudo rm -rf $1/*
        echo "Deleted contents of $1"
    fi
}

function tscCheck() {
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

function storageCleanup() {
    yay -Scc
    delete /var/log/journal/*
    delete /var/lib/systemd/coredump/*
}

function debugLogs() {
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

function toFlac() {
    findFiles $1 | parallel ffmpeg -i "{}" -c:a flac -sample_fmt s32 "{.}.flac"
}

function flacToOpus() {
    findFiles flac | parallel opusenc --bitrate $1 "{}" "{.}.opus"
}

function tagMusic() {
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

function downloadMusic() {
    yt-dlp --format 251 --extract-audio --audio-format "opus" $1 -o "%(title)s.%(ext)s"
}

function mkvDefaultTrack() {
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

function toMKV() {
    findFiles $1 | parallel mkvmerge -o "{.}.mkv" "{}"
}

function removeTracks() {
# Audio and Subtitle tracks not chosen by $1 and $2 will be removed
    findFiles mkv | parallel mkvmerge -o "Muxed/{}" -a $1 -s $2 "{}"
}

function addSubs() {
    findFiles $1 | parallel mkvmerge -o "Muxed/{}" "{}" "{.}".srt
}

function toJxl() {
    local type=""
    read -p "Image Type: " type
    echo ".$type images chosen"
    findFiles $type | parallel cjxl "{}" "{.}.jxl"
}

function videoState() {
    # $1 The file containing the list of videos
    cat $1 | while read video
    do
#         echo $video
        if [[ -f "$video" ]]
        then
            bakup "$video"
            echo "Disabled $video"
        elif [[ -f "$video.bak" ]]
        then
            rstore "$video"
            echo "Restored $video"
        else
            echo "Video not found"
        fi
    done
}

# Gaming

# Gaming-Wine

function wineKill() {
    kill -9 $(ps -ef | grep -E -i "(wine|processid|\.exe)" | awk "{print $2}")
    killall -9 pressure-vessel-adverb
}

function downloadDirectX() {
    curl -s https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest | grep -o "https.*zst" | wget -i -
    curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest | grep -om 1 "https.*tar.gz" | wget -i -
}

function dx11() {
    echo "Installing DXVK (DirectX 8,9,10,11)"
    $HOME/Sync/Gaming/DXVK/setup_dxvk.sh install --symlink
}
function dx12() {
    echo "Installing VKD3D-Proton (DirectX 12)"
    $HOME/Sync/Gaming/VKD3D-Proton/setup_vkd3d_proton.sh install --symlink
}

function dxSetup() {
    dx11
    dx12
}

# Gaming-Emulation

function crom() {
    case $1 in
    "chdDVD")
        findFiles2 iso bin | parallel chdman createdvd -f -i "{}" -o "{.}.chd" ;;
    "chdCD")
        findFiles cue | parallel chdman createcd -f -i "{}" -o "{.}.chd"gr ;;
    *)
        echo "Incorrect or no option chosen"
    esac
}

function crom7z {
    findFiles $1 | parallel --bar 7z a -mx9 "{.}.7z" "{}"

}

function recrom() {
    ark --batch --autodestination *.7z
    mvrom $1
}

function mvrom() {
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

function backupGameSaves() {
    local savesDir="$HOME/Games/Game Saves"
    local savesFile="Game Saves - $(date +"%d-%m-%Y")"
    7z a -mx9 "$savesFile.7z" "$savesDir"
}

function changeGameIntro() {
    if [[ -f "videos.txt" ]]
    then 
        videoState "videos.txt"
    else
        echo "videos.txt not found"
    fi
}

function changeGPUState() {
    local gpuLevel=/sys/class/drm/card1/device/power_dpm_force_performance_level
    echo "Current GPU Level: $(cat $gpuLevel)"
    echo "Setting GPU Level to $1"
    sudo sh -c "echo $1 > $gpuLevel"
    echo "Current GPU Level: $(cat $gpuLevel)"
}

# Pi

function piBackupSettings() {
    local option=""
    echo "Pi Backup Settings V1"
    echo "1 - Backup"
    echo "2 - Restore"
    read -p "Would you like to backup or restore? " option
    case $option in
    1)
        local backupFile="piSettings_$(date +"%d-%m-%Y").tar"
        local backupDir="/srv/nfs/Backup/Linux/pi/"
        local tempFolder="piSettings"
        # Create and move to the folder to extract the settings into
        mkdir $tempFolder
        cd $tempFolder
        # Create the folder layout for extracted settings
        echo "Creating folders"
        mkdir {etc,var,var/lib,.local,.local/state,.ssh}
        # Copy all the settings files
        echo "Copying settings"
        sudo cp -r -p /var/lib/jellyfin var/lib/
        sudo cp -r -p /etc/jellyfin etc/
        cp -p $HOME/.profile .profile
        cp -p $HOME/.bashrc .bashrc
        cp -p $HOME/.ssh/authorized_keys .ssh/authorized_keys
        cp -r -p /etc/samba etc/
        cp -p /etc/fstab etc/fstab
        cp -r -p $HOME/.local/state/syncthing .local/state
        cp -p /boot/cmdline.txt cmdline.txt
        cd ../
        echo "Creating tar file"
        sudo tar -cf "$backupFile" $tempFolder/
        echo "Copying $backupFile to $backupDir"
        cp -p $backupFile $backupDir
        sudo rm -R $tempFolder
        rm -f $backupFile
        echo "Removing leftover files"
        echo "Done" ;;
    2)
        cd $HOME/piSettings
        # Set pi as the owner of all the files
        echo "Changing the owner and group of all files to pi"
        sudo chown -R pi:pi *
        echo "Restoring files"
        cp -p .profile $HOME/.profile
        cp -p .bashrc $HOME/.bashrc
        cp -p .ssh/authorized_keys $HOME/.ssh/authorized_keys
        cp -r -p .local/state/syncthing $HOME/.local/state
        sudo cp -r -p var/lib/jellyfin /var/lib/
        sudo cp -r -p etc/jellyfin /etc/
        sudo cp -r -p etc/samba /etc/
        sudo cp -p etc/fstab /etc/fstab
        sudo cp -p cmdline.txt /boot/cmdline.txt
        sudo chown -R jellyfin:adm /etc/jellyfin/
        sudo chown -R jellyfin:adm /var/lib/jellyfin ;;
    *)
        echo "Incorrect or no option chosen"
    esac
}

# Git

function buildMesa() {
    local oldLocation=$PWD
    cd "$HOME/Git/mesa"
    git pull
    git status
    time ninja -C build64/ install
    time ninja -C build32/ install
    cd $oldLocation
    rm -rf $HOME/.cache/mesa_shader_cache_sf
}

function configureMesa() {
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

function buildLinuxTSC() {
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
    cpuCheck
    echo
    gpuCheck
    echo
    echo "System"
    echo "......................"
    echo "Kernel               : $(uname -r)"
    echo "glibc                : $(ldd --version | grep ldd | awk '{print $4}')"
    echo "vm.max_map_count     : $(cat /proc/sys/vm/max_map_count)"
    echo "DefaultLimitNOFILE   : $(ulimit -Hn)"
    echo
    utilitiesCheck
}

function test_amd_s2idle() {
    local dest="amd_s2idle"
    mkdir $dest
    cd $dest
    wget https://gitlab.freedesktop.org/drm/amd/-/raw/master/scripts/amd_s2idle.py
    sudo python amd_s2idle.py
}
