#!/bin/bash
# package.sh for BennuGD_libretro on PS2

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

## Configure using CMake for PS2/libretro
mkdir -p build && cd build

# Pre-create ogg build directory structure and write correct types header to bypass CheckSizes.cmake
mkdir -p _deps/ogg-build/include/ogg
cat << 'EOF' > "_deps/ogg-build/include/ogg/config_types.h"
#ifndef _OGG_TYPES_H
#define _OGG_TYPES_H
#include <sys/types.h>
#include <stdint.h>
typedef int16_t ogg_int16_t;
typedef uint16_t ogg_uint16_t;
typedef int32_t ogg_int32_t;
typedef uint32_t ogg_uint32_t;
typedef int64_t ogg_int64_t;
typedef uint64_t ogg_uint64_t;
#endif
EOF

export CFLAGS="-O3 -G0 -ffat-lto-objects"
export CXXFLAGS="-O3 -G0 -ffat-lto-objects"

cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="${PS2DEV}/share/ps2dev.cmake" \
    -DTHREADS_HAVE_PTHREAD_ARG=OFF \
    -DCMAKE_BUILD_TYPE=Release || { exit 1; }

# Build using parallel cores with verbose logs enabled
make -j $PROC_NR VERBOSE=1 || { exit 1; }

cd ../.. || { exit 1; }

## Locate and copy the generated static archive to target locations
GENERATED_LIB=$(find "$REPO_FOLDER/build" -name "*.a" | head -n 1)

if [ -z "$GENERATED_LIB" ]; then
    echo "Error: Could not find generated BennuGD libretro archive!"
    exit 1
fi

cp -f "$GENERATED_LIB" ./libretro_ps2.a || { exit 1; }

mkdir -p BennuGD_libretro
cp -f "$GENERATED_LIB" BennuGD_libretro/BennuGD_libretro_ps2.a || { exit 1; }