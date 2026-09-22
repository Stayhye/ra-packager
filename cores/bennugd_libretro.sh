#!/bin/bash
# package.sh for BennuGD_libretro on PS2
set -e

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/BennuGD_libretro"
REPO_FOLDER="bennugd_libretro"
BRANCH_NAME="master"

# Ensure ps2dev toolchain bin paths are fully exposed
export PS2DEV=/usr/local/ps2dev
export PS2SDK=$PS2DEV/ps2sdk
export PATH=$PS2DEV/bin:$PS2SDK/bin:$PS2DEV/ee/bin:$PATH

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd "$REPO_FOLDER" || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Clean build directory to avoid cache conflicts
rm -rf build
mkdir -p build && cd build || { exit 1; }

# Export strict toolchain paths and explicit standard include folders for the PS2 SDK headers
export CC="/usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-gcc"
export CXX="/usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-g++"
export AR="/usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-ar"
export RANLIB="/usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-ranlib"

# Expose ps2sdk and gcc internal include directories cleanly, and force-include stddef.h globally via GCC
PS2_INC_DIR="/usr/local/ps2dev/ee/mips64r5900el-ps2-elf/include"
GCC_INC_DIR="$($CC -print-file-name=include)"
GCC_FIXED_INC_DIR="$($CC -print-file-name=include-fixed)"

export CFLAGS="-I$PS2SDK/ee/include -I$PS2SDK/common/include -I$PS2_INC_DIR -I$GCC_INC_DIR -I$GCC_FIXED_INC_DIR -include stddef.h"
export CPPFLAGS="$CFLAGS"

## Configure using CMake with absolute paths to compiler and archiver for PS2
cmake .. \
    -DCMAKE_SYSTEM_NAME=Generic \
    -DCMAKE_SYSTEM_PROCESSOR=mips \
    -DCMAKE_C_COMPILER=$CC \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DCMAKE_AR=$AR \
    -DCMAKE_RANLIB=$RANLIB \
    -DCMAKE_BUILD_TYPE=Release || { exit 1; }

# Build with verbose output
cmake --build . --target bennugd_libretro --verbose || { exit 1; }

## Go back to the repository root folder
cd ..

## Copy the compiled library to the root of the repo folder with the ps2 suffix
if [ -f "build/bennugd_libretro.a" ]; then
    cp build/bennugd_libretro.a bennugd_libretro_ps2.a
elif [ -f "build/lib/bennugd_libretro.a" ]; then
    cp build/lib/bennugd_libretro.a bennugd_libretro_ps2.a
else
    find build -name "*bennugd_libretro*.a" -exec cp {} bennugd_libretro_ps2.a \;
fi

echo "Successfully built and placed bennugd_libretro_ps2.a in repo root."