#!/bin/bash
# mame2003-plus.sh

# --- FIX: Initialize PS2DEV Environment ---
export PS2DEV=/usr/local/ps2dev
export PS2SDK=$PS2DEV/ps2sdk
export PATH=$PATH:$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin:$PS2SDK/bin

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/libretro/mame2003-plus-libretro"
REPO_FOLDER="mame2003-plus-libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL && cd $REPO_FOLDER || { exit 1; }
else
    cd $REPO_FOLDER && git fetch origin && git reset --hard origin/${BRANCH_NAME} && git checkout ${BRANCH_NAME} || { exit 1; }
fi

## Compile core for PS2
# Explicitly setting the compiler variables ensures the Makefile uses the EE toolchain
make -f Makefile -j $PROC_NR platform=ps2 CC=ee-gcc CXX=ee-g++ AR=ee-ar clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 CC=ee-gcc CXX=ee-g++ AR=ee-ar || { exit 1; }

cd .. || { exit 1; }
