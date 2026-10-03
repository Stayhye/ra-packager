#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/amiberry"
REPO_FOLDER="amiberry"
BRANCH_NAME="master"


if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

cd libretro || { exit 1; }

## Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 FLAGS="-march=r5900 -mtune=r5900 -G0 -ffast-math -fomit-frame-pointer -DPS2 -DABGR1555 -fno-expensive-optimizations -DLIBRETRO_NO_JIT -DCPU_MIPS -DEE -D_EE -DLSB_FIRST -D_POSIX_C_SOURCE=200809L -D_DEFAULT_SOURCE -Wno-error=incompatible-pointer-types" || { exit 1; }