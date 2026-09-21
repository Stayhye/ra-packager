#!/bin/bash
# package.sh for Anarch (PS2 target)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/anarch-libretro"
REPO_FOLDER="anarch-libretro"
BRANCH_NAME="main"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Create build directory for CMake
mkdir -p build && cd build || { exit 1; }

## Configure and Compile using CMake (targeting PS2)
cmake .. -DCMAKE_SYSTEM_NAME=PS2 -DCMAKE_BUILD_TYPE=Release || { exit 1; }
cmake --build . -- -j $PROC_NR || { exit 1; }

## Go back to the repository root folder
cd ..

## Copy and rename the compiled library to the workspace root directory
if [ -f "build/anarch_libretro_ps2.a" ]; then
    cp build/anarch_libretro_ps2.a ../anarch_libretro_ps2.a
else
    # Fallback to catch any variant naming convention
    find build -name "*.a" -exec cp {} ../anarch_libretro_ps2.a \;
fi