#!/bin/bash
# package.sh for Anarch (PS2 target)
set -e

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/anarch-libretro"
REPO_FOLDER="anarch_libretro"
BRANCH_NAME="main"

# Ensure ps2dev toolchain paths are fully exposed to the environment
export PS2DEV=/usr/local/ps2dev
export PS2SDK=$PS2DEV/ps2sdk
export PATH=$PS2DEV/bin:$PS2SDK/bin:$PS2DEV/ee/bin:$PATH

REPO_URL="https://github.com/Stayhye/anarch-libretro"
REPO_FOLDER="anarch_libretro"
BRANCH_NAME="main"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd "$REPO_FOLDER" || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Create build directory for CMake
mkdir -p build && cd build || { exit 1; }

## Configure using explicit toolchain definitions and environment bindings
cmake .. \
    -DCMAKE_SYSTEM_NAME=Generic \
    -DCMAKE_SYSTEM_PROCESSOR=mips \
    -DCMAKE_C_COMPILER=mips64r5900el-ps2-elf-gcc \
    -DCMAKE_AR=mips64r5900el-ps2-elf-ar \
    -DCMAKE_RANLIB=mips64r5900el-ps2-elf-ranlib \
    -DCMAKE_BUILD_TYPE=Release || { exit 1; }

cmake --build . -- -j $PROC_NR || { exit 1; }

## Go back to the repository root folder
cd ..

## Copy the compiled library to the root of the repo folder 
if [ -f "build/anarch_libretro_ps2.a" ]; then
    cp build/anarch_libretro_ps2.a anarch_libretro_ps2.a
else
    find build -name "*.a" -exec cp {} anarch_libretro_ps2.a \;
fi

echo "Successfully built and placed anarch_libretro_ps2.a in repo root."