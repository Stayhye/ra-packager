#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Download the source code.
##REPO_URL="https://github.com/fjtrujy/libretro-prboom"
##REPO_URL="https://github.com/libretro/libretro-prboom"
REPO_URL="https://github.com/Stayhye/libretro-prboom"
REPO_FOLDER="libretro-prboom"
##BRANCH_NAME="fix-dynamic-platforms"
BRANCH_NAME="master"
##BRANCH_NAME="ps2-support"
if test ! -d "$REPO_FOLDER"; then
	git clone --depth 1 -b $BRANCH_NAME $REPO_URL && cd $REPO_FOLDER || { exit 1; }
else
	cd $REPO_FOLDER && git fetch origin && git reset --hard origin/${BRANCH_NAME} && git checkout ${BRANCH_NAME} || { exit 1; }
fi


## Compile core
make -j $PROC_NR platform=ps2 clean  || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

cd .. || { exit 1; }
