#!/bin/bash
# package.sh

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/mame2000-libretro.git"
REPO_FOLDER="mame2000-libretro"
BRANCH_NAME="ps2"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core using native platform=ps2 support from the root directory
make -j $PROC_NR platform=ps2 || { exit 1; }

## Inspect binary size and sections locally in the script (without destroying symbols)
FOUND_ARCHIVE=$(find . -name "*_ps2.a" | head -n 1)
if [ -n "$FOUND_ARCHIVE" ]; then
    echo "=== File Size ==="
    ls -lh "$FOUND_ARCHIVE"
    
    echo "=== Section Breakdown ==="
    mips64r5900el-ps2-elf-size -A "$FOUND_ARCHIVE"
    
    echo "=== Top 20 Largest Symbols ==="
    mips64r5900el-ps2-elf-nm --size-sort -S "$FOUND_ARCHIVE" | tail -n 20
fi

## Return back to the workspace root
cd .. || { exit 1; }

## Find and copy the generated archive
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*_ps2.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p mame2000-libretro
cp -f "$FOUND_ARCHIVE" mame2000-libretro/mame2000-libretro_ps2.a || { exit 1; }