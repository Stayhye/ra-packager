#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/mgba-emu/mgba"
REPO_FOLDER="mgba"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core using the correct path to Makefile.libretro
make -C ports/libretro -f Makefile.libretro -j $PROC_NR platform=ps2 clean || { exit 1; }
make -C ports/libretro -f Makefile.libretro -j $PROC_NR platform=ps2 || { exit 1; }

cd .. || { exit 1; }

## Copy the generated static archive to both locations
cp -f "$REPO_FOLDER/ports/libretro/mgba_libretro_ps2.a" ./libretro_ps2.a || { exit 1; }

mkdir -p mgba
cp -f "$REPO_FOLDER/ports/libretro/mgba_libretro_ps2.a" mgba/mgba_libretro_ps2.a || { exit 1; }