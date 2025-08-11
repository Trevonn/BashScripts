#!/bin/bash

crom() {
        chdman create$1 -f -i "$2" -o "${2%.*}.chd"
    }
    
cromPS3() {
    local dest=$ROMS_DIR/Sony/PS3/games/"$1"
    rsync -ahW --info=progress2 --no-compress --mkpath --chmod=755 {PS3_GAME,PS3_DISC.SFB} "$dest"
}

cromBatch() {
    case $1 in
    "dvd")
        find -type f -iname "*.iso" -or -iname "*.bin" | parallel chdman createdvd -f -i "{}" -o "{.}.chd" 
        ;;
    "cd")
        find -type f -iname "*.cue" | parallel chdman createcd -f -i "{}" -o "{.}.chd" 
        ;;
    "7z")
        find -type f -iname "*.$2" | parallel --bar 7z a -mx9 "{.}.7z" "{}" 
        ;;
    *)
        echo "Incorrect or no option chosen"
    esac
}

mvrom() {
    local type="$1"
    local dest=""
    case $1 in
        "nes")
            cromBatch 7z $type
            type="7z"
            dest="$ROMS_DIR/Nintendo/NES" 
            ;;
        "n64")
            cromBatch 7z $type
            type="7z"
            dest="$ROMS_DIR/Nintendo/N64" 
            ;;
        "gba")
            cromBatch 7z $type
            type="7z"
            dest="$ROMS_DIR/Nintendo/GBA" 
            ;;
        "nds")
            cromBatch 7z $type
            type="7z"
            dest="$ROMS_DIR/Nintendo/DS" 
            ;;
        "3ds")
            dest="$ROMS_DIR/Nintendo/3DS" 
            ;;
        "switch")
            type="nsp"
            dest="$ROMS_DIR/Nintendo/Switch" 
            ;;
        "ps1")
            dest="$ROMS_DIR/Sony/PS1"
            type="cd"
            cromBatch $type
            type="chd" 
            ;;
        "ps2")
            dest="$ROMS_DIR/Sony/PS2"
            type="dvd"
            cromBatch $type
            type="chd" 
            ;;
        "psp")
            dest="$ROMS_DIR/Sony/PSP"
            type="dvd"
            cromBatch $type
            type="chd" 
            ;;
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
