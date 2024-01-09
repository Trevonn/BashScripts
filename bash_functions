# General

function mkcd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

function findFiles() {
    find -type f -name "*.$1"
}

function filesExist() {
    local list=$(find ./ -type f \( -iname \*."$1" -o -iname \*."$2" \))
    if [ -z "$list" ]
    then
        echo "No files found"
        return
    else
        echo "Files found"
    fi
}

function findFiles2() {
    find ./ -type f \( -iname \*."$1" -o -iname \*."$2" \)
}

function to7z() {
    7z a -mx9 "${1%.$2}.7z" "$1"
}

function folderExistDelete() {
    if [ -d "$1" ] 
    then 
        sudo rm -R "$1"
        echo "$1 deleted"
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

function arewetsc() {
    # Store the current clocksource in a local variable
    local tscCheck=$(cat /sys/devices/system/clocksource/clocksource*/current_clocksource)

    # Check the value of the variable. Print a message to journalctl depending on the result
    if [ $tscCheck == "tsc" ] 
    then
        echo "TSC active" | systemd-cat -p info
        echo "TSC active"
    else
        echo "TSC not active" | systemd-cat -p emerg
        echo "TSC not active"
    fi
}

function clean() {
    yay -Sc
    folderEmptyDelete /var/log/journal
    folderEmptyDelete /var/lib/systemd/coredump
    folderEmptyDelete /var/cache/pacman/pkg
}

# Music

function toFlac() {
    findFiles $1 | {
        while read file ; do
            ffmpeg -i "$file" -c:a flac -sample_fmt s32 "${file%.$1}.flac"
        done
    }
}

function eAudio() {
    findFiles flac | {
        while read file ; do
            opusenc --bitrate $1 "$file" "${file%.flac}.opus"
        done
    }
}

function tag() {
    if [[ "$1" == "title" ]]
    then 
        kid3-cli -c "select *.opus" -c "totag '%{title}' 2"
    elif [[ "$1" == "alt" ]]
    then
        kid3-cli -c "select *.opus" -c "set Album 'Alt EDM'"
        tag title
    else
        echo "Fail"
    fi
}

function dMusic() {
    yt-dlp --format 251 --extract-audio --audio-format "opus" $1 -o "%(title)s.%(ext)s"
}

function altEDM() {
    eAudio 160
    tag alt
    mv ./*.opus "$HOME/Music/Electronic/Alt EDM"
}

function dMusicAlt {
    dMusic $1
    altEDM
}


# Video

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
    findFiles mkv | {
        while read file ; do
            mkvpropedit "$file" --edit track:$trackType$trackNum --set flag-default=$trackDef --set flag-forced=$trackForced
        done
    }
}

function toMKV() {
    findFiles $1 | {
        while read file ; do
            mkvmerge -o "${file%.$1}".mkv "$file"
        done
    }
}

function removeTracks() {
    findFiles mkv | {
        while read file ; do
            mkvmerge -o "${file%.mkv}"-fixed.mkv -$1 $2 "$file"
        done
    }
}

function removeTracks2() {
    findFiles mkv | {
        while read file ; do
            mkvmerge -o "${file%.mkv}"-fixed.mkv -a $1 -s $2 "$file"
        done
    }
}

function addSubs() {
    findFiles mkv | {
        while read file ; do
            mkvmerge -o Fixed/"${file%.mkv}".mkv "$file" "${file%.mkv}".srt
        done
    }
}

function mkvInfo() {
    findFiles mkv | {
        while read file ; do
            mkvmerge -i "$file"
        done
    }
}

# Images

function toJxl() {
    findFiles $1 | {
        while read file ; do
            cjxl "$file" "${file%.$1}.jxl"
        done
    }
}

# Gaming

function ueFix() {
    if [[ -f "$PWD/Engine.ini" ]]
    then
        cat $HOME/Sync/Config/Gaming/Other/Engine.ini >> "$PWD/Engine.ini"
    else
        cp $HOME/Sync/Config/Gaming/Other/Engine.ini "$PWD/Engine.ini"
    fi
}

function dx11() {
    echo "Installing DXVK (DirectX 9,10,11)"
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

function setupPrefix() {
    WINEPREFIX="$PWD/$1" wineboot
    WINEPREFIX="$PWD/$1" winetricks sandbox
    WINEPREFIX="$PWD/$1" winecfg
    WINEPREFIX="$PWD/$1" dxAll
}

# Emulation

function updateEmulators() {
    local dest=$HOME/Sync/AppImages
    curl -s https://api.github.com/repos/yuzu-emu/yuzu-mainline/releases/latest | grep -v -e "zsync" | grep -wo "https.*mainline.*AppImage" | wget -i - -O yuzu.AppImage
    curl -s https://api.github.com/repos/PCSX2/pcsx2/releases | jq -r ".[0].assets[] | .browser_download_url" | grep -wo "https.*AppImage" | wget -i - -O PCSX2.AppImage
    curl -s https://api.github.com/repos/RPCS3/rpcs3-binaries-linux/releases/latest | grep -wo "https.*AppImage" | wget -i - -O RPCS3.AppImage
    
    chmod +x *.AppImage
    mv *.AppImage $dest
}

function crom() {
    filesExist iso cue
    
    if [[ "$1" == "chd" ]]
    then
        findFiles2 iso cue | {
            while read rom ; do
                echo "Compressing ${rom%.*} using chdman"
                chdman createcd -i "${rom}" -o "${rom%.*}.chd"
            done
        }
    elif [[ "$1" == "cso" ]]
    then
        findFiles iso | {
            while read rom ; do
                echo "Compressing ${rom%.iso} using maxcso"
                maxcso "$rom" -o "${rom%.iso}.cso"
            done
        }
    fi
}

function crom7z {
    filesExist $1
    findFiles $1 | {
            while read rom ; do
                echo "Compressing ${rom%.$1} using 7-Zip"
                to7z "$rom" $1
            done
    }
}

function recrom() {
    ark --batch --autodestination *.7z
    mvrom $1
}

function mvrom() {

    local type="$1"
    local dest=""

    if [ "$1" == "nes" ]
    then
        crom7z $type
        type="7z"
        dest="$HOME/Games/Emulation/ROMs/Nintendo/NES"
    elif [ "$1" == "n64" ]
    then
        crom7z $type
        type="7z"
        dest="$HOME/Games/Emulation/ROMs/Nintendo/N64"
    elif [ "$1" == "gba" ]
    then
        crom7z $type
        type="7z"
        dest="$HOME/Games/Emulation/ROMs/Nintendo/GBA"
    elif [ "$1" == "nds" ]
    then
        crom7z $type
        type="7z"
        dest="$HOME/Games/Emulation/ROMs/Nintendo/DS"
    elif [ "$1" == "3ds" ]
    then
        dest="$HOME/Games/Emulation/ROMs/Nintendo/3DS"
    elif [ "$1" == "switch" ]
    then
        type="xci"
        dest="$HOME/Games/Emulation/ROMs/Nintendo/Switch"
    elif [ "$1" == "ps2" ]
    then
        dest="$HOME/Games/Emulation/ROMs/Sony/PS2"
        type="chd"
        crom $type
    elif [ "$1" == "ps1" ]
    then
        dest="$HOME/Games/Emulation/ROMs/Sony/PS1"
        type="chd"
        crom $type
    elif [ "$1" == "psp" ]
    then
        dest="$HOME/Games/Emulation/ROMs/Sony/PSP"
        type="cso"
        crom $type
    else
        echo "Choose a file type!"
        echo " n64    - Nintendo 64"
        echo " gba    - GameBoy Advance"
        echo " nds    - Nintendo DS"
        echo " 3ds    - Nintendo 3DS"
        echo " switch - Nintendo Switch"
        echo " ps1    - PlayStation 1"
        echo " ps2 - PlayStation 2 ISO"
        echo " psp    - PlayStation Portable"
        return
    fi
    
    echo "Moving .$type files to $dest"
    mv *.$type "$dest"
}

# Pi 

function piExtractSettings() {
    mkdir piSettings
    cd piSettings
    # Create the folder to extract the settings into
    mkdir {etc,var,var/lib,.config}
    # Create the folder layout for extracted settings
    sudo cp -r -p /var/lib/jellyfin var/lib/
    sudo cp -r -p /etc/jellyfin etc/
    cp -r -p /etc/samba etc/
    cp -p /etc/fstab etc/fstab
    cp -r -p $HOME/.config/syncthing .config
    cp -p /boot/cmdline.txt cmdline.txt
    # Copy all the settings files
    sudo chown -R pi:pi *
    # Set pi as the owner of all the files
}

function piRestoreSettings() {
    cd $HOME/piSettings
    sudo cp -r -p var/lib/jellyfin /var/lib/
    sudo cp -r -p etc/jellyfin /etc/
    sudo cp -r -p etc/samba /etc/
    sudo cp -p etc/fstab /etc/fstab
    cp -r -p .config/syncthing $HOME/.config
    sudo cp -p cmdline.txt /boot/cmdline.txt
    sudo chown -R jellyfin:adm /etc/jellyfin/
    sudo chown -R jellyfin:adm /var/lib/jellyfin
}

# Git

function buildMesa() {
    local oldLocation=$PWD
    cd $MESA_GIT
    git pull
    git status
    time ninja -C build64/ install
    time ninja -C build32/ install
    cd $oldLocation
}

function configureMesa() {
    local oldLocation=$PWD
    local selection=""
    local mesaSync="$HOME/Sync/Gaming/Mesa"
    echo "Mesa Configurator 1.0"
    echo "Option 1: radv"
    echo "Option 2: zink"
    echo "Option 3: radv+radeonsi(aco)"
    read -p "Choose an option: " selection
    if [[ "$selection" == "1" ]]
    then
        cd $MESA_GIT
        meson setup --reconfigure build64 --libdir lib64 --prefix $mesaSync -Dbuildtype=release -Dgallium-drivers= -Dvulkan-drivers=amd -Dllvm=disabled
        meson setup --reconfigure build32 --cross-file gcc-i686 --libdir lib --prefix $mesaSync -Dgallium-drivers= -Dvulkan-drivers=amd -Dllvm=disabled -Dbuildtype=release
    elif [[ "$selection" == "2" ]]
    then
        cd $MESA_GIT
        meson setup --reconfigure build64 --libdir lib64 --prefix $mesaSync -Dbuildtype=release -Dgallium-drivers=zink -Dvulkan-drivers=amd -Dllvm=disabled
        meson setup --reconfigure build32 --cross-file gcc-i686 --libdir lib --prefix $mesaSync -Dgallium-drivers=zink -Dvulkan-drivers=amd -Dllvm=disabled -Dbuildtype=release
    elif [[ "$selection" == "3" ]]
    then
        cd $MESA_GIT
        meson setup --reconfigure build64 --libdir lib64 --prefix $mesaSync -Dbuildtype=release -Dgallium-drivers=radeonsi,zink -Dvulkan-drivers=amd -Dllvm=disabled
        meson setup --reconfigure build32 --cross-file gcc-i686 --libdir lib --prefix $mesaSync -Dgallium-drivers=radeonsi,zink -Dvulkan-drivers=amd -Dllvm=disabled -Dbuildtype=release
    else
        echo "No option chosen"
    fi
    cd $oldLocation
}

function buildLinux() {
    local patches="$HOME/Sync/Config/Kernel/"
    pkgctl repo clone --protocol=https linux
    cd linux
    cp $patches/tsc.patch tsc.patch
    patch -i $patches/PKGBUILD.patch PKGBUILD
    time makepkg --syncdeps --skipinteg
}

function schedInfo() {
    local cpufreq=/sys/devices/system/cpu/cpu0/cpufreq/
    echo "CPU Scaling Governor : $(cat $cpufreq/scaling_governor)"
    echo "CPU Scaling Driver   : $(cat $cpufreq/scaling_driver)"
    echo "AMD EPP Preference   : $(cat $cpufreq/energy_performance_preference)"
}

function changeTurboBoost() {
    local epp="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver)"
    if [[ $epp = amd-pstate ]] then
        sudo cpupower set --turbo-boost $1
    else
        echo "amd_pstate is not set to passive"
    fi
}

function changeGPUState() {
    local gpuLevel=/sys/class/drm/card1/device/power_dpm_force_performance_level
    echo "Current GPU Level: $(cat $gpuLevel)"
    echo "Setting GPU Level to $1"
    sudo sh -c "echo $1 > $gpuLevel"
    echo "Current GPU Level: $(cat $gpuLevel)"
}
