#!/bin/bash
# package.sh

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/Geargrafx"
##REPO_URL="https://github.com/libretro/mame2000-libretro.git"
REPO_FOLDER="geargrafx-libretro"
BRANCH_NAME="main"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core using native platform=ps2 support from the root directory
make -j $PROC_NR platform=ps2 || { exit 1; }

## Return back to the workspace root
cd .. || { exit 1; }

## Find and copy the generated archive
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*_ps2.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p geargrafx-libretro
cp -f "$FOUND_ARCHIVE" geargrafx-libretro/geargrafx-libretro_ps2.a || { exit 1; }