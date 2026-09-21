#!/bin/bash
set -e

PROC_NR=$(getconf _NPROCESSORS_ONLN)
REPO_URL="https://github.com/Stayhye/anarch-libretro"
REPO_FOLDER="anarch_libretro"
BRANCH_NAME="main"

# Lock in the workspace root before changing directories
WORKSPACE_ROOT=$(pwd)

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER
fi

cd "$REPO_FOLDER"
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME}

mkdir -p build
cd build

cmake .. -DCMAKE_SYSTEM_NAME=PS2 -DCMAKE_BUILD_TYPE=Release
cmake --build . -- -j $PROC_NR

# Copy directly using the tracked workspace root path
cp anarch_libretro_ps2.a "$WORKSPACE_ROOT/anarch_libretro_ps2.a"

echo "Successfully built and copied anarch_libretro_ps2.a to root."