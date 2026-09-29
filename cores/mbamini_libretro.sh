#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)
# Optimized for direct recursive object linking on PS2 libretro ports

set -e # Exit immediately if a command exits with a non-zero status

PROC_NR=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)
REPO_URL="https://github.com/Stayhye/MBA.mini-libretro"
REPO_FOLDER="mbamini_libretro"
BRANCH_NAME="master"

# Clone or update repository efficiently
if [ ! -d "$REPO_FOLDER" ]; then
    git clone --recurse-submodules --depth 1 -b "$BRANCH_NAME" "$REPO_URL" "$REPO_FOLDER"
else
    cd "$REPO_FOLDER"
    git fetch origin
    git reset --hard "origin/${BRANCH_NAME}"
    git checkout "$BRANCH_NAME"
    cd ..
fi

# PS2 Environment Setup
export PS2DEV="/usr/local/ps2dev"
export PS2SDK="$PS2DEV/ps2sdk"
export PATH="$PATH:$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2SDK/bin"

# Compile core
cd "$REPO_FOLDER"
make -f makefile platform=ps2 clean
mkdir -p obj/retro/mame
make -f makefile -j "$PROC_NR" platform=ps2
cd ..

# Verify repository folder exists
if [ ! -d "$REPO_FOLDER" ]; then
    echo "Error: Repository folder '$REPO_FOLDER' not found!" >&2
    exit 1
fi

# Collect all compiled object files recursively across the repo into a single space-separated string
OBJS=$(find "$REPO_FOLDER" -name '*.o' | tr '\n' ' ')
OBJ_COUNT=$(echo "$OBJS" | wc -w)

if [ "$OBJ_COUNT" -eq 0 ]; then
    echo "Error: No object files found to link!" >&2
    exit 1
fi

echo "Successfully compiled and queued $OBJ_COUNT object files for direct linking!"

# Pass the grouped objects directly into RetroArch's build system
# (Adjust 'make -f Makefile.ps2' or whatever command builds RetroArch here if needed, 
# ensuring LIBS or EXTRALINK receives the grouped objects)