#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/libretro-vecx"
REPO_FOLDER="vecx_libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core with HAVE_OPENGL=0
make -f Makefile.libretro -j $PROC_NR platform=ps2 HAVE_OPENGL=0 clean || { exit 1; }
make -f Makefile.libretro -j $PROC_NR platform=ps2 HAVE_OPENGL=0 || { exit 1; }