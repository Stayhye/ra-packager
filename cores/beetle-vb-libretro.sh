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

## Clean and compile with explicit PS2 cross-compiler flags to prevent x86_64 fallback
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 \
    CC=mips64r5900el-ps2-elf-gcc \
    CXX=mips64r5900el-ps2-elf-g++ \
    AR=mips64r5900el-ps2-elf-ar \
    LD=mips64r5900el-ps2-elf-ld || { exit 1; }

cd .. || { exit 1; }