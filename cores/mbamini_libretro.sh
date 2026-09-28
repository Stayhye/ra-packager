#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/MBA.mini-libretro"
REPO_FOLDER="mbamini_libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# PS2 Environment Setup
export PS2DEV=/usr/local/ps2dev
export PS2SDK=$PS2DEV/ps2sdk
export PATH=$PATH:$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2SDK/bin

# Compile core
make -f makefile platform=ps2 clean || { exit 1; }

# Ensure the required object directory tree exists prior to parallel building
mkdir -p obj/retro/mame

make -f makefile -j $PROC_NR platform=ps2 || { exit 1; }

# Go back to root project directory where RetroArch links everything
cd ..

# Force the final linker to include the static library with whole-archive so no libretro symbols are dropped
export LIBS="-Wl,--whole-archive -L$REPO_FOLDER -lmbamini_libretro_ps2 -Wl,--no-whole-archive $LIBS"

if [ -f "$REPO_FOLDER/mbamini_libretro_ps2.a" ]; then
    echo "Successfully built and exported LIBS with whole-archive for $REPO_FOLDER/mbamini_libretro_ps2.a"
fi