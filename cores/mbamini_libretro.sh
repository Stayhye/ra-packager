#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)
# Optimized for direct object linking on PS2 libretro ports

set -e # Exit immediately if a command exits with a non-zero status

PROC_NR=$(getconf _NPROCESSORS_ONLN)
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

# Verify and collect all compiled object files for direct linking
OBJ_DIR="$REPO_FOLDER/obj"
if [ ! -d "$OBJ_DIR" ]; then
    echo "Error: Object directory '$OBJ_DIR' not found!" >&2
    exit 1
fi

OBJS=$(find "$OBJ_DIR" -name '*.o')
OBJ_COUNT=$(echo "$OBJS" | grep -c '\.o$')

if [ "$OBJ_COUNT" -eq 0 ]; then
    echo "Error: No object files found to link!" >&2
    exit 1
fi

# Inject directly into LIBS, bypassing static archive symbol-dropping issues
export LIBS="$OBJS $LIBS"

echo "Successfully compiled $OBJ_COUNT object files and prepared them for direct linking!"