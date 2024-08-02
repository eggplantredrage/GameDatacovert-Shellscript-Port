#!/bin/bash

# GameDataConvert.sh
# Based on a vanilla Oni (Windows or Mac) GameDataFolder, creates a GameDataFolderX for use with OniX

set -e

HAS_SEP=0
RAWSEP_MISSING=0

echo "== OniX game data converter v1.1 Ported to Shellscript By Eggplant48=="

# ==========================
echo "Inspecting Oni environment..."
if [ ! -f GameDataTool ]; then
    echo "GameDataTool not found. GameDataTool needs to be placed alongside this script."
    exit 1
fi

if [ ! -d GameDataFolder ]; then
    echo "There is no GameDataFolder present here. The folder needs to be placed alongside this script."
    echo "If you do not own a copy of Oni, you can download the demo from Oni Mod Depot."
    echo "Visit http://mods.oni2.net/ and search for 'demo' to get it."
    exit 1
fi

PRIOR_GDFX=0
if [ -d GameDataFolderX ]; then
    # We are not concerned with other things that might be in GDFX, just the level files
    if ls GameDataFolderX/level*.dat 1> /dev/null 2>&1 || \
       ls GameDataFolderX/level*.raw 1> /dev/null 2>&1 || \
       ls GameDataFolderX/level*.sep 1> /dev/null 2>&1; then
        PRIOR_GDFX=1
    fi
    if [ "$PRIOR_GDFX" -eq 1 ]; then
        echo "Existing GameDataFolderX detected. Your previously-converted game data will be overwritten."
        read -p "Do you want to remove the previous contents of GameDataFolderX and run the conversion again? (y/n) " CHOICE
        if [ "$CHOICE" = "y" ]; then
            rm -f GameDataFolderX/level*.dat GameDataFolderX/level*.raw GameDataFolderX/level*.sep
            echo "Removed previous conversion products in GameDataFolderX."
        else
            exit 0
        fi
    fi
fi

PRIOR_CONV=0
for file in GameDataFolder/level*.dat; do
    if [ -d "GameDataFolder/$(basename "$file" .dat)" ]; then
        PRIOR_CONV=1
    fi
    if [ -f "GameDataFolder/$(basename "$file" .dat).log" ]; then
        PRIOR_CONV=1
    fi
done
if [ "$PRIOR_CONV" -eq 1 ]; then
    echo "Products of an earlier conversion detected in GameDataFolder. Do you want to remove them and run the conversion again?"
    read -p "(y/n) " CHOICE
    if [ "$CHOICE" = "y" ]; then
        for file in GameDataFolder/level*.dat; do
            folder="GameDataFolder/$(basename "$file" .dat)"
            if [ -d "$folder" ]; then
                rm -rf "$folder"
            fi
            if [ -f "GameDataFolder/$(basename "$file" .dat).log" ]; then
                rm "GameDataFolder/$(basename "$file" .dat).log"
            fi
        done
        echo "Removed previous conversion products in GameDataFolder."
    else
        exit 0
    fi
fi

if [ "$PRIOR_GDFX" -eq 0 ] && [ "$PRIOR_CONV" -eq 0 ]; then
    echo "All clear."
fi

# ==========================
echo "Checking for game data..."
FAILED_RETAIL_VAL=0
FAILED_DEMO_VAL=0
for N in 0 1 2 3 4 6 8 9 10 11 12 13 14 18 19; do
    if [ ! -f "GameDataFolder/level${N}_Final.dat" ]; then
        FAILED_RETAIL_VAL=1
        echo "level${N}_Final.dat not found."
    fi
done

if [ "$FAILED_RETAIL_VAL" -eq 1 ]; then
    # Only our repackaged demo contains all three levels, but that's okay because it's highly
    # unlikely that they're using the original self-destructing demo and trying to convert it
    for N in 0 1 2 4; do
        if [ ! -f "GameDataFolder/level${N}_Final.dat" ]; then
            FAILED_DEMO_VAL=1
            echo "level${N}_Final.dat not found."
        fi
    done

    if [ "$FAILED_DEMO_VAL" -eq 1 ]; then
        echo "Some of the game data files needed for running Oni are missing. Supply a retail or"
        echo "demo copy of Oni. Visit http://mods.oni2.net/ and search for 'demo' to get the demo."
        exit 1
    else
        echo "This is the demo installation of Oni. There's no need to convert it if this is the"
        echo "Windows demo, as the game data uses the same format as OniX. If this is the Mac demo,"
        echo "you should visit http://mods.oni2.net/, search for 'demo', and download the Windows"
        echo "version, which comes with OniX and is ready to play."
        exit 0
    fi
else
    echo "Retail data detected."
fi

# ==========================
echo "Determining platform version of game data..."
if ls GameDataFolder/level*.sep 1> /dev/null 2>&1; then
    HAS_SEP=1
    echo "Found some .sep files; assuming this is Mac data."
else
    echo "No .sep files detected; assuming this is Windows data."
fi

# ==========================
echo "Ensuring completeness of game data..."
for file in GameDataFolder/level*.dat; do
    base_name=$(basename "$file" .dat)
    if [ ! -f "GameDataFolder/${base_name}.raw" ]; then
        RAWSEP_MISSING=1
        echo "${base_name}.raw not found."
    fi

    if [ "$HAS_SEP" -eq 1 ]; then
        if [ ! -f "GameDataFolder/${base_name}.sep" ]; then
            RAWSEP_MISSING=1
            echo "${base_name}.sep not found."
        fi
    fi
done
if [ "$RAWSEP_MISSING" -eq 1 ]; then
    echo "GameDataFolder needs to contain a full set of game data files. The file(s) above are missing."
    exit 1
fi
echo "All needed files present."

# ==========================
echo "Testing privileges..."
GameDataTool -export:TXMPKONdeepthought GameDataFolder/level0_Final GameDataFolder/level0_Final.dat > /dev/null
if [ $? -ne 0 ]; then
    echo "This script does not seem to have sufficient privileges to write to GameDataFolder. Are"
    echo "you an administrator? Do you have ownership of the Oni folder? You could try moving the"
    echo "entire Oni folder to another drive, or to your desktop. If that does not work, you will"
    echo "need to get Properties on the Oni folder and use the Security tab to give yourself more"
    echo "rights to it and all subfolders."
    exit 1
fi
rm -rf GameDataFolder/level0_Final
echo "Privileges sufficient."

# ==========================
echo "Converting the game data..."
for file in GameDataFolder/level*.dat; do
    FNAME=$(basename "$file" .dat)
    # Construct a hypothetical folder name; GameDataTool will create it if it doesn't exist, as well as GDFX
    FOLDER="GameDataFolder/${FNAME}"

    echo "Exporting vanilla-format ${FNAME}..."
    GameDataTool -export "$FOLDER" "GameDataFolder/${FNAME}.dat" > "GameDataFolder/${FNAME}.log"
    if [ $? -ne 0 ]; then
        echo "An error was encountered while converting the game data."
        echo "Look at GameDataFolder/${FNAME}.log to see the issue."
        exit 1
    fi
    GameDataTool -move "$FOLDER/SNDD" "$FOLDER/SNDD*.oni" > /dev/null
    if [ $? -ne 0 ]; then
        echo "An error was encountered while moving sound files."
        exit 1
    fi

    echo "Extracting sounds..."
    if [ -f "${FNAME}.sep" ]; then
        GameDataTool -extract:aif "$FOLDER/SNDD/aif" "$FOLDER/SNDD/SNDD*.oni" >> "GameDataFolder/${FNAME}.log" 2>&1
        if [ $? -ne 0 ]; then
            echo "An error was encountered while extracting sounds."
            exit 1
        fi
        echo "Reformatting sounds..."
        GameDataTool -create "$FOLDER" -demo -forcestd "$FOLDER/SNDD/aif/SNDD*.aif" >> "GameDataFolder/${FNAME}.log"
        if [ $? -ne 0 ]; then
            echo "An error was encountered while reformatting sounds."
            exit 1
        fi
    else
        GameDataTool
