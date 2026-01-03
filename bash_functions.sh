#!/bin/bash

# General

mkcd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

nvmeHealth() {
    sudo nvme smart-log -H /dev/nvme$1
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

dockerKill() {
    docker kill $1
    docker rm $1
    docker container prune
}

dockerUpdate() {
    dockerFile="$SYNC_DIR/Scripts/Docker/docker-compose.yaml"
    docker-compose -f $dockerFile pull
    docker-compose -f $dockerFile up -d
    docker image prune -af
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
    
    find -type f -iname "*.mkv" | while read film
        do
            mkvpropedit "$film" --edit track:$trackType$trackNum --set flag-default=$trackDef
        done
}

downsampleMovieAudio() {
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

if [[ -f /usr/bin/pacman ]] then
    pacin() {
        sudo pacman -U *.$1
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

rencode10() {
    # if the input file is mkv output the file in a different directory
    if [[ $1 != "mkv" ]] then
        dest="."
    else
        dest="Re-Encoded"
        mkdir $dest
    fi
    
    find -type f -name "*.$1" | while read video
    do  
        ffmpeg -nostdin -vaapi_device /dev/dri/renderD128 -i "$video" -vf 'format=nv12,hwupload' -c:v av1_vaapi -b:v 10M -c:a copy "$dest/${video%.*}.mkv"
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
        /usr/lib/jellyfin-ffmpeg/ffmpeg -y -hide_banner -stats -fflags +genpts+igndts -loglevel error -i "$1" -map 0 -bsf:v hevc_metadata=remove_dovi=1 -codec copy -max_muxing_queue_size 2048 -max_interleave_delta 0 -avoid_negative_ts disabled "${1%.*}-nodv.mkv"
    }
fi

# Gaming

# Gaming - Emulation

# Extracts mounted PS3 disc to the RPCS3 disc folder
# $1 Name of the game
extract_ps3_disc() {
    local dest=$ROMS_DIR/Sony/PS3/games/"$1"
    rsync -ahW --info=progress2 --no-compress --mkpath --chmod=755 {PS3_GAME,PS3_DISC.SFB} "$dest"
}

# Gaming-Wine

wineKill() {
    kill -9 $(ps -ef | grep -E -i "(wine|processid|\.exe)" | awk "{print $2}")
    killall -9 pressure-vessel-adverb
}

githubDownload() {
    # $1 = file extension of the file to be downloaded
    wcurl $(curl -s $2 | jq -r .assets.[].browser_download_url | grep $1)
}

downloadProtonGE() {
    local dest="$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton-latest"
    sudo rm -r "$dest"
    githubDownload .zst https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest
    mkdir "$dest"
    tar -xf GE-Proton*.tar.zst -C "$dest" --strip-components 1
    ln -s $HOME/Sync/Config/Gaming/Steam/user_settings.py "$dest"/user_settings.py
    rm GE-Proton*.tar.zst
}

downloadDXVK() {
    githubDownload .gz "https://api.github.com/repos/doitsujin/dxvk/releases/latest"
    tar -xf dxvk*.tar.gz -C $HOME/Games/DirectX/DXVK --strip-components 1
    rm dxvk*.tar.gz
}

downloadVKD3D() {
    githubDownload .zst "https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest"
    tar -xf vkd3d*.tar.zst -C $HOME/Games/DirectX/VKD3D-Proton --strip-components 1
    rm vkd3d*.tar.zst
}

downloadDirectX() {
    downloadDXVK
    downloadVKD3D
}

# Gaming-GPU

changeGpuState() {
    local gpuLevel="/sys/class/drm/card1/device/power_dpm_force_performance_level"
    echo "Current GPU Level: $(cat $gpuLevel)"
    echo "Setting GPU Level to $1"
    echo $1 | sudo tee "$gpuLevel" > /dev/null
    echo "Current GPU Level: $(cat $gpuLevel)"
}

resetGpu() {
    local gpuCfgFile="/sys/class/drm/card1/device/pp_od_clk_voltage"
    echo "r" > sudo tee $gpuCfgFile > /dev/null
    echo "c" > sudo tee $gpuCfgFile > /dev/null
}

gpuPowerCap() {
    local powerCap="$(find /sys/class/drm/card1/device/hwmon -type f -name power1_cap)"

    if [[ -f "$powerCap" ]] then
        cat "$powerCap"
    fi
}

# Misc

nasBackup() {
    timestamp=$(date +"%Y-%m-%d")
    backupDir="/mnt/NAS/Backup/Auto/$timestamp"
    mkdir "$backupDir"
    backupFile="$backupDir/$1 - Backup - $timestamp.tar.zst"
    tar -I "zstd --ultra -22 -T$(nproc)" -cf "$backupFile" "$2"
}

if [[ -f /usr/bin/pkgctl ]] then
    downloadArchPackage() {
        pkgctl repo clone --protocol=https $1
    }
    
    patchKernel() {
        local patches="$SYNC_DIR/Config/Kernel/$1"
        cp $patches/tsc.patch tsc.patch
        patch -i $patches/PKGBUILD.patch PKGBUILD
    }
    
    buildKernel() {
        local option="" 
        local kernel=""
        echo "Kernel with TSC Patch builder"
        echo "1: linux"
        echo "2: linux-lts"
        read -p "Choose a kernel to build: " option
        if [[ $option == 1 ]] then
            kernel="linux"
        elif [[ $option == 2 ]] then
            kernel="linux-lts"
        fi
        sudo rm -r $kernel
        downloadArchPackage $kernel
        cd $kernel
        patchKernel $kernel
        makepkg -s --skipinteg --asdeps
        cd ../
        sudo rm -r $kernel
    }
fi
