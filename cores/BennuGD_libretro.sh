#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/BennuGD_libretro"
REPO_FOLDER="BennuGD_libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Configure and compile using CMake for PS2/libretro
mkdir -p build && cd build

export CFLAGS="-O3 -fno-lto -ffat-lto-objects"
export CXXFLAGS="-O3 -fno-lto -ffat-lto-objects"

cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="${PS2DEV}/share/ps2dev.cmake" \
    -DBUILD_LIBRETRO=ON \
    -DENABLE_LTO=OFF \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
    -DCMAKE_AR="${PS2DEV}/ee/bin/mips64r5900el-ps2-elf-ar" \
    -DCMAKE_RANLIB="${PS2DEV}/ee/bin/mips64r5900el-ps2-elf-ranlib" \
    -DCMAKE_BUILD_TYPE=Release || { exit 1; }

# Build ONLY the libretro target to skip desktop binaries/tests
make -j $PROC_NR mgba_libretro || { exit 1; }

cd ../.. || { exit 1; }

## Locate and copy the generated static archive to both locations
GENERATED_LIB=$(find "$REPO_FOLDER/build" -name "*libretro*.a" | head -n 1)

if [ -z "$GENERATED_LIB" ]; then
    echo "Error: Could not find generated mGBA libretro archive!"
    exit 1
fi

cp -f "$GENERATED_LIB" ./libretro_ps2.a || { exit 1; }

mkdir -p BennuGD_libretro
cp -f "$GENERATED_LIB" BennuGD_libretro/BennuGD_libretro_ps2.a || { exit 1; }