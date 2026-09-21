#!/bin/bash
# package.sh for Anarch (PS2 target)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/anarch-libretro"
REPO_FOLDER="anarch_libretro"
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

## Go back to the repository root, then to the workspace root
cd ..
cd ..

## Copy and rename the compiled library to the workspace root directory
if [ -f "anarch_libretro/build/anarch_libretro_ps2.a" ]; then
    cp anarch_libretro/build/anarch_libretro_ps2.a anarch_libretro_ps2.a
else
    find anarch_libretro -name "anarch_libretro_ps2.a" -exec cp {} . \;
fi