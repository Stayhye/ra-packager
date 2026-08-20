#!/bin/bash
# package.sh

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/mame2000-libretro.git"
REPO_FOLDER="mame2000-libretro"
BRANCH_NAME="ps2-gcc9"

if test ! -d "$REPO_FOLDER"; then
	git clone --recursive --depth 1 -b $BRANCH_NAME $REPO_URL && cd $REPO_FOLDER || { exit 1; }
else
	cd $REPO_FOLDER && git fetch origin && git reset --hard origin/${BRANCH_NAME} && git checkout ${BRANCH_NAME} && git submodule update --init --recursive || { exit 1; }
fi

make -j $PROC_NR platform=ps2 clean || exit 1
make -j $PROC_NR platform=ps2 || exit 1

cd .. || exit 1