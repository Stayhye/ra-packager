#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Download the source code.
#REPO_URL="https://github.com/libretro/picodrive"
REPO_URL="https://github.com/Stayhye/PicoDrive_PS2_DVD"
REPO_FOLDER="PicoDrive_PS2_DVD"
BRANCH_NAME="main"

if test ! -d "$REPO_FOLDER"; then
	git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL && cd $REPO_FOLDER || { exit 1; }
else
	cd $REPO_FOLDER && git fetch origin && git reset --hard origin/${BRANCH_NAME} && git checkout ${BRANCH_NAME} || { exit 1; }
fi

## Compile core
make -f Makefile.libretro -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile.libretro  -j $PROC_NR platform=ps2 || { exit 1; }

cd .. || { exit 1; }
