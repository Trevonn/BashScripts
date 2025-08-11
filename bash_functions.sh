#!/bin/bash

# General

mkcd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

nvmeHealth() {
    sudo nvme smart-log -H /dev/nvme$1
}

firmwareUpdate() {
    fwupdmgr refresh --force
    fwupdmgr get-updates
    fwupdmgr update
}

to7z() {
    7z a -mx9 "${1%.$2}.7z" "$1"
}

toZst() {
    tar -I "zstd --ultra -22 -T$(nproc)" -cf $1.tar.zst $1
}

delete() {
    if [[ -d "$1" ]] then
        rm -r "$1"
        if [[ -d "$1" ]] then
            sudo rm -r "$1"
        fi
        echo "Deleted folder $1"
    elif [[ -f "$1" ]] then
        rm "$1"
        if [[ -f "$1" ]] then
            sudo rm "$1"
        fi
        echo "Deleted file $1"
    else
        echo "$1 not found"
    fi
}

sendTo() {
    scp $2 $USER@$1:$HOME/Downloads
}

dockerKill() {
    docker kill $1
    docker rm $1
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

downloadMusic() {
    yt-dlp --format 251 --extract-audio --audio-format "opus" $1 -o "%(title)s.%(ext)s"
}

mkvDefaultTrack() {
    mkvpropedit $1 --edit track:$2$3 --set flag-default=$4 --set flag-forced=$5
}

mkvDefaultTrackBatch() {
    echo "MKV Default Track Changer Batch 1.0"
    echo "This script lets you change the default track properties in an MKV"
    echo
    local trackType=""
    local trackNum=""
    local trackDef=""
    local trackForced=""

    echo "MKV Default Track Selector"
    read -p "Default track type: audio or subtitle (a/s): " trackType
    read -p "Choose a track number: " trackNum
    read -p "Set the track number as default? (0,1): " trackDef
    read -p "Set the track number as forced (0,1) " trackForced
    find -type f -iname "*.mkv" | parallel mkvDefaultTrack "{}" $trackType $trackNum $trackDef $trackForced
}

downsampleAudio() {
    mkdir Muxed
    find -type f -iname "$1" | parallel ffmpeg -y -i "{}" -map 0 -c copy -c:a:0 aac -b:a:0 256k -ac 2 "Muxed/{}"
}

toMKV() {
    find -type f -iname "*.$1" | parallel mkvmerge -o "{.}.mkv" "{}"
}

removeTracks() {
    mkvmerge -o "Muxed/$1" -a $2 -s $3 "$1"
}

batchRemoveTracks() {
    # Audio and Subtitle tracks not chosen by $1 and $2 will be removed
    find -type f -iname "*.mkv" | parallel mkvmerge -o "Muxed/{}" -a $1 -s $2 "{}"
}

addSubs() {
    local videoExt=""
    read -p "Video File Extension Type: " videoExt
    find -type f -iname "*.$videoExt" | parallel mkvmerge -o "Muxed/{.}.mkv" "{}" "{.}"*.srt
}

toJxl() {
    find -type f -iname "*.$1" | parallel cjxl "{}" "{.}.jxl"
}

restoreTar() {
    local backupFile=""
    ls -l *.{tar,tar.zst}
    read -p "Which tar file would you like to restore: " backupFile
    sudo tar -P -xf "$backupFile"
}

if [[ -f /usr/bin/pacman ]] then
    pacin() {
        pacman -U *.$1
    }
    
    cacheClear() {
        find "$XDG_CACHE_HOME" -iregex '.*\.\(jsc\|qmlc\)' -type f -mtime +1 -delete
        find "$XDG_CACHE_HOME" -iname "ksycoca6*" -type f -mtime +1 -delete
        find "$XDG_CACHE_HOME/qtshadercache-x86_64-little_endian-lp64/" -name "*" -type f -mtime +1 -delete
        find "$XDG_CACHE_HOME" -name "*.qsb" -mtime +7 -delete
        find "$XDG_CACHE_HOME" -name "_qt_QGfxShaderBuilder_*" -delete
        #find "$XDG_CACHE_HOME/qtshadercache/" -name "*" -type f -mtime +1 -delete
        find "$XDG_CACHE_HOME/fontconfig/" -name "*" -type f -mtime +7 -delete
        #rm -r $XDG_CACHE_HOME/python/*
        echo "Cleared various cache files"
    }
    
    storageCleanup() {
        yay -Scc
        sudo rm -r /var/log/*
        echo "Cleared /var/log/"
        sudo rm -r /var/cache/*
        echo "Cleared /var/cache/"
        sudo rm /var/lib/systemd/coredump/*
        echo "Cleared /var/lib/systemd/coredump"
        cacheClear
        
    }
    
    archBackup() {
        # Get a timestamp
        local timestamp=$(date +"%Y-%m-%d")
        # Define the backup folder
        local backupFolder="Arch Backup - $HOSTNAME - $timestamp"
        local backupLocation="/mnt/NAS/Backup/Linux/Pacman"
        # Create the backup folder
        mkdir "$backupFolder"
        # Create a text list of locally installed pacman packages
        pacman -Qn | awk '{print $1}' > "$backupFolder"/pacman.txt
        # Create a text list of locally installed aur packages
        pacman -Qm | awk '{print $1}' > "$backupFolder"/aur.txt
        # Compress the folder into a tar file
        tar -I "zstd --ultra -22 -T$(nproc)" -cf "$backupFolder.tar.zst" "$backupFolder"
        # Remove leftover folder and files
        rm -r "$backupFolder"
        if [[ -d $backupLocation ]] then
            cp "$backupFolder.tar.zst" $backupLocation
        else
            scp "$backupFolder.tar.zst" $USER@nas:$backupLocation
        fi
    }
fi

resetDevice() {
    local option=""
    local module=""
    local name=""
    echo "Device Reset 1.0"
    echo "1: Bluetooth               - btusb"
    echo "2: Intel WiFi              - iwlmvm"
    echo "3: Mediatek WiFi           - mt7921e"
    echo "4: PlayStation Controllers - hid_playstation, hid_sony"
    echo "5: Logitech Devices        - hid_logitech_dj, hid_logitech_hidp"
    read -p "Option: " option
    case $option in
        1)
            module="btusb" 
            name="Bluetooth" 
            ;;
        2)
            module="iwlmvm" 
            name="Intel WiFi" 
            ;;
        3)
            module="mt7921e" 
            name="Meditek WiFi" 
            ;;
        4)
            module="hid_playstation hid_sony" 
            name="Playstation Controllers" 
            ;;
        5)
            module="hid_logitech_dj hid_logitech_hidpp" 
            name="Logitech Devices" 
            ;;
        *)
            echo "Incorrect or no option chosen"
            return
    esac
    echo "Resetting $name - module/s: $module"
    sudo rmmod $module && sudo modprobe $module
}

# Media

videoState() {
# $1 The file containing the list of videos
cat $1 | while read video
    do
        if [[ -f "$video" ]] then
            mv "$video" "$video".bak
            echo "Disabled $video"
        elif [[ -f "$video.bak" ]] then
            mv "$video".bak "$video"
            echo "Restored $video"
        else
            echo "Video not found: $video"
        fi
    done
}

toFlac() {
    find -type f -iname "*.$1" | parallel ffmpeg -i "{}" -c:a flac -sample_fmt s32 "{.}.flac"
}

flacToOpus() {
    find -type f -iname "*.flac" | parallel opusenc --bitrate $1 "{}" "{.}.opus"
}

tagMusic() {
    case $1 in
    "title")
        kid3-cli -c "select *.opus" -c "totag '%{title}' 2" 
        ;;
    "album")
        kid3-cli -c "select *.opus" -c "set Album '$2'" 
        ;;
    *)
        echo "Argument must be title or album"
    esac
}

if [[ -f /usr/lib/jellyfin-ffmpeg/ffmpeg ]] then
    removeDolbyVision() {
        mkvpropedit "$1" --delete-attachment mime-type:image/png
        mkvpropedit "$1" --delete-attachment mime-type:image/jpeg
        /usr/lib/jellyfin-ffmpeg/ffmpeg -y -hide_banner -stats -fflags +genpts+igndts -loglevel error -i "$1" -map 0 -bsf:v hevc_metadata=remove_dovi=1 -codec copy -max_muxing_queue_size 2048 -max_interleave_delta 0 -avoid_negative_ts disabled ../"$1"
    }
fi

# Gaming

# Gaming-Wine

wineKill() {
    kill -9 $(ps -ef | grep -E -i "(wine|processid|\.exe)" | awk "{print $2}")
    killall -9 pressure-vessel-adverb
}

downloadDirectX() {
    mkdir {DXVK,VKD3D-Proton}
    curl -s https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest | grep -o "https.*zst" | wget -i -
    curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest | grep -om 1 "https.*tar.gz" | wget -i -
    tar -xf dxvk*.tar.gz -C DXVK --strip-components 1
    tar -xf vkd3d*.tar.zst -C VKD3D-Proton --strip-components 1
    rm dxvk*.tar.gz
    rm vkd3d*.tar.zst
}

# Gaming-GPU

passiveOndemand() {
    sudo cpupower set --amd-pstate-mode passive
    sudo cpupower frequency-set -g ondemand
}

changeGpuState() {
    local gpuLevel=/sys/class/drm/card1/device/power_dpm_force_performance_level
    echo "Current GPU Level: $(cat $gpuLevel)"
    echo "Setting GPU Level to $1"
    sudo sh -c "echo $1 > $gpuLevel"
    echo "Current GPU Level: $(cat $gpuLevel)"
}

confirmGpuSettings() {
    sudo sh -c "echo c > /sys/class/drm/card1/device/pp_od_clk_voltage"
    echo "Applied new gpu settings"
}

changeGpuVoltage() {
    sudo sh -c "echo \"vo -120\" > /sys/class/drm/card1/device/pp_od_clk_voltage"
}

    changeGpuClockOffset() {
    sudo sh -c "echo \"so -500\" > /sys/class/drm/card1/device/pp_od_clk_voltage"
}

resetGpu() {
    sudo sh -c "echo r > /sys/class/drm/card1/device/pp_od_clk_voltage"
    confirmGpuSettings
}

fixGpuClock() {
    sudo sh -c "echo s 0 $1 > /sys/class/drm/card1/device/pp_od_clk_voltage"
    echo "Set minimum GPU clock to $1 MHz"
    sudo sh -c "echo s 1 $1 > /sys/class/drm/card1/device/pp_od_clk_voltage"
    echo "Set maximum GPU clock to $1 MHz"
    confirmGpuSettings
}

# Misc

nasBackup() {
    timestamp=$(date +"%Y-%m-%d")
    backupDir="/mnt/NAS/Backup/Auto/$timestamp"
    mkdir "$backupDir"
    backupFile="$backupDir/$1 - Backup - $timestamp.tar.zst"
    tar -I "zstd --ultra -22 -T$(nproc)" -cf "$backupFile" "$2"
}

downloadPackage() {
    pkgctl repo clone --protocol=https $1
}

patchKernel() {
    local patches="$SYNC_DIR/Config/Kernel/$1"
    cp $patches/tsc.patch tsc.patch
    patch -i $patches/PKGBUILD.patch PKGBUILD
}

buildKernel() {
    local kernel=""
    echo "Kernel with TSC Patch builder"
    echo "1: linux"
    echo "2: linux-lts"
    read -p "Choose a kernel to build: " kernel
    if [[ $kernel == 1 ]] then
        kernel="linux"
    elif [[ $kernel == 2 ]] then
        kernel="linux-lts"
    fi
    downloadPackage $kernel
    cd $kernel
    patchKernel $kernel
    mPkg
    cd ../
    sudo rm -r $kernel
}

configureMesa() {
    local oldLocation=$PWD
    local option=""
    local mesaSync=$MESA_GIT_DIR/Git
    local message="Configured for "
    local setup64cmd="meson setup --reconfigure build64 --libdir lib64 --prefix $mesaSync -Dbuildtype=release -Dvideo-codecs= -Dvulkan-drivers=amd -Dllvm=disabled -Dgallium-drivers"
    local setup32cmd="meson setup --reconfigure build32 --cross-file gcc-i686 --libdir lib --prefix $mesaSync -Dbuildtype=release -Dvulkan-drivers=amd -Dllvm=disabled -Dgallium-drivers"
    echo "Mesa Configurator 1.0"
    echo "1: RADV 64-Bit"
    echo "2: RADV 32+64-Bit"
    echo "3: RADV+Zink 32+64-Bit"
    read -p "Choose an option: " option
    cd "$MESA_GIT_SRC"
    case $option in
    1)
        # = completes the build command
        setup64cmd+="="
        message+="RADV 64-Bit"
        rm -r $MESA_GIT_SRC/build32/
        ;;
    2)
        # = completes the build command
        setup64cmd+="="
        setup32cmd+="="
        message+="RADV 32+64-Bit"
        $setup32cmd
        ;;
    3)
        # =zink completes the build command
        setup64cmd+="=zink"
        setup32cmd+="=zink"
        message+="RADV+Zink 32+64-Bit" 
        $setup32cmd
        ;;
    *)
        echo "Incorrect or no option chosen"
        return
    esac

    $setup64cmd
    echo $message
    cd $oldLocation
}

buildMesa() {
    git -C $MESA_GIT_SRC pull
    git -C $MESA_GIT_SRC status
    time ninja -C $MESA_GIT_SRC/build64/ install
#        time ninja -C $MESA_GIT_SRC/build32/ install
    delete $MESA_GIT_DIR/Git/mesa_shader_cache_sf
    delete $MESA_GIT_DIR/Git/radv_builtin_shaders
}
