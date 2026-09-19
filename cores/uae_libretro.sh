#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/libretro-uae"
REPO_FOLDER="uae_libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }

# Fix conflicting integer types between sysdeps.h and types.h for PS2 toolchain
sed -i '/typedef unsigned int uae_u32;/s/^/\/\//' sources/src/include/sysdeps.h
sed -i '/typedef int uae_s32;/s/^/\/\//' sources/src/include/sysdeps.h
sed -i '/typedef uae_u32 uaecptr;/s/^/\/\//' sources/src/include/sysdeps.h

# Fix timezone macro conflict
sed -i '/#define timezone 0/s/^/\/\//' sources/src/include/sysdeps.h
# Completely drop any caps source files from Makefile.common to prevent undefined references to uae_dlopen/dlsym
sed -i '/caps/d' Makefile.common

make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }

