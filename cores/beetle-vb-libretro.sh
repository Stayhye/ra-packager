#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/libretro/beetle-vb-libretro"
REPO_FOLDER="beetle-vb-libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core using native platform=ps2 support from Makefile
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

cd .. || { exit 1; }

## Locate the generated static archive dynamically in the repo folder
GENERATED_LIB=$(find "$REPO_FOLDER" -maxdepth 1 -name "*libretro_ps2.a" | head -n 1)

if [ -z "$GENERATED_LIB" ]; then
    echo "Error: Could not find generated libretro_ps2.a file!"
    exit 1
fi

## Copy the generated archive to both locations
cp -f "$GENERATED_LIB" ./libretro_ps2.a || { exit 1; }

mkdir -p beetle-vb-libretro
cp -f "$GENERATED_LIB" beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }
