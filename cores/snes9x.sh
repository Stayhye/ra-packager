#!/bin/bash
# package.sh for Anarch (PS2 target)
set -e

# Ensure the PS2 SDK cross-compilers are in the PATH
export PATH=$PATH:/usr/local/ps2dev/ee/bin

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/snes9x"
REPO_FOLDER="snes9x"
BRANCH_NAME="master"


if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

cd libretro || { exit 1; }
# Compile core using native platform=ps2 support and explicitly define the MIPS compilers
make -j $PROC_NR platform=ps2 \
    CC=mips64r5900el-ps2-elf-gcc \
    CXX=mips64r5900el-ps2-elf-g++ \
    AR=mips64r5900el-ps2-elf-ar clean || { exit 1; }

make -j $PROC_NR platform=ps2 \
    CC=mips64r5900el-ps2-elf-gcc \
    CXX=mips64r5900el-ps2-elf-g++ \
    AR=mips64r5900el-ps2-elf-ar || { exit 1; }

# Fix: Move the compiled core back to the root 
# so the subsequent CI/CD steps can find it.
cp snes9x_libretro_ps2.a ../ || { exit 1; }