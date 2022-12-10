# General

function mkcd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

function clean() {
    yay -Sc
    sudo rm -rf /var/log/journal/*
    echo "Cleaned journal logs"
    sudo rm -rf /var/lib/systemd/coredump/*
    echo "Cleaned coredumps"
    sudo rm -rf /var/cache/pacman/pkg/*
    echo "Cleaned pacman cache"
}

# Music

function eaudio() {
    find -type f -name '*.flac' | {
        for file in ./*.flac; do
            opusenc --bitrate $1 "$file" "${file%.flac}.opus"
        done
    }
}

function eaudio2() {
    find -type f -name '*.$1' | {
        for file in ./*.$1; do
            #opusenc --bitrate $2 "$file" "${file%.$1}.opus"
            ffmpeg -i "$file" -b:a $2 -ac $3 "${file%.$1}.$4"
        done
    }
}

function tag() {
    if [ "$1" == "title" ]
    then 
        kid3-cli -c "select *.opus" -c "totag '%{title}' 2"
    elif [ "$1" == "single" ]
    then
        kid3-cli -c "select *.opus" -c "set Album 'Singles'"
        tag title
    elif [ "$1" == "alt" ]
    then
        kid3-cli -c "select *.opus" -c "set Album 'Alt EDM'"
        tag title
    else
        echo "Fail"
    fi
}

function altedm() {
    eaudio 160
    tag alt
    mv ./*.opus "$HOME/Music/Electronic/Alt EDM"
}

function dmusic() {
    yt-dlp --format 251 --extract-audio --audio-format "opus" $1 -o "%(title)s.%(ext)s"
}

function dmusicalt {
    dmusic $1
    altedm
}

function dmusicsing {
    dmusic $1
    tag single
}


# Video 

function defaultAudio2() {
    find -type f -name '*.mkv' | {
        while read file ; do
            #mkvpropedit "$file" --edit track:a1 --set flag-default=0 --edit track:a2 --set flag-default=1
            mkvmerge -o $file-fixed --atracks 2 $file
        done
    }
}

# Images

function tojxl() {
    find -type f -name '*.$1' | {
        for file in ./*.$1; do
            cjxl "$file" "${file%.$1}.jxl"
        done
    }
}

# Gaming

function gog() {
    innoextract *.exe --language en-US -g -m -d $1
#    mv $1 $HOME/Games/GOG/
}

function dx11() {
    echo "Installing DXVK (DirectX 9,10,11)"
    $HOME/Sync/Gaming/DXVK/Installer/setup_dxvk.sh install --symlink
}
function dx12() {
    echo "Installing VKD3D-Proton (DirectX 12)"
    $HOME/Sync/Gaming/VKD3D/Installer/setup_vkd3d_proton.sh install --symlink
}

# Emulation

function crom {
    if [ "$1" == "chd" ]
    then
        if [ -f *.$2 ] # $2 Can be .cue or .iso
        then
            echo "Compressing using chdman"
            for romFile in *.$2; do
                gameName="$(basename "$romFile" .$2)"
                echo "Converting ${gameName}..."
                chdman createcd -i "${romFile}" -o "${gameName}.chd"
            done
        fi
    elif [ "$1" == "cso" ]
    then
        if [ -f *.iso ]
        then
            echo "Compressing using maxcso"
            for isoFile in ./*.iso; do
                gameName="$(basename "$isoFile" .iso)"
                maxcso "$isoFile" -o "${gameName}.cso"
            done
        else
            echo "No .iso files found"
        fi
    else
        echo "No option selected. You need to choose chd (chdman) or cso (maxcso)"
    fi
}


function recrom() {
#    unzip *\.zip
    ark --batch --autodestination *.7z
    mvrom $1
}

function mvrom() {

    if [ "$1" == "n64" ]
    then
        mv ./*.n64 "$HOME/Games/Emulation/ROMs/Nintendo/N64"
    elif [ "$1" == "gba" ]
    then 
        mv ./*.gba "$HOME/Games/Emulation/ROMs/Nintendo/GBA"
    elif [ "$1" == "ds" ]
    then 
        mv ./*.nds "$HOME/Games/Emulation/ROMs/Nintendo/DS"
    elif [ "$1" == "3ds" ]
    then 
        mv ./*.3ds "$HOME/Games/Emulation/ROMs/Nintendo/3DS"
    elif [ "$1" == "ps2iso" ]
    then
        crom chd iso
        mv ./*.chd "$HOME/Games/Emulation/ROMs/Sony/PS2"
    elif [ "$1" == "ps2cue" ]
    then
        crom chd cue
        mv ./*.chd "$HOME/Games/Emulation/ROMs/Sony/PS2"
    elif [ "$1" == "ps1" ]
    then
        ecm2bin *.ecm
        crom chd
        mv ./*.chd "$HOME/Games/Emulation/ROMs/Sony/PS1"
    elif [ "$1" == "psp" ]
    then
        crom cso
        mv ./*.cso "$HOME/Games/Emulation/ROMs/Sony/PSP"
    else
        echo "Choose a file type!"
        echo " n64    - Nintendo 64"
        echo " gba    - GameBoy Advance"
        echo " ds     - Nintendo DS"
        echo " 3ds    - Nintendo 3DS"
        echo " ps1    - PlayStation 1"
        echo " ps2iso - PlayStation 2 ISO"
        echo " ps2cue - PlayStation 2 CUE+BIN"
        echo " psp    - PlayStation Portable" 
    fi
}
