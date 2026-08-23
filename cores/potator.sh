#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/potator"
REPO_FOLDER="potator"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Navigate into the platform/libretro directory where the Makefile is located
cd platform/libretro || { exit 1; }

## Compile core using native platform=ps2 support
make -j $PROC_NR platform=ps2 || { exit 1; }

## Return back to the root workspace directory (where the script started)
cd ../../.. || { exit 1; }

## Find the generated archive inside the repo folder from the workspace root
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*_ps2.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p potator
cp -f "$FOUND_ARCHIVE" potator/potator_libretro_ps2.a || { exit 1; }