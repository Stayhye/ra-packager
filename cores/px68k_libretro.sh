#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/px68k-libretro"
REPO_FOLDER="px68k_libretro"
BRANCH_NAME="master"


if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core
make -f Makefile.libretro -j $PROC_NR platform=ps2 clean || { exit 1; }

# Fix conflicting types error for GetPrivateProfileInt in peace.c
sed -i 's/uint32_t GetPrivateProfileInt/unsigned int GetPrivateProfileInt/g' libretro/peace.c

make -f Makefile.libretro -j $PROC_NR platform=ps2 || { exit 1; }