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

## Configure using CMake for PS2/libretro (this downloads deps via FetchContent)
mkdir -p build && cd build

export CFLAGS="-O3 -G0 -ffat-lto-objects"
export CXXFLAGS="-O3 -G0 -ffat-lto-objects"

cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="${PS2DEV}/share/ps2dev.cmake" \
    -DTHREADS_HAVE_PTHREAD_ARG=OFF \
    -DCMAKE_BUILD_TYPE=Release

# Patch ogg type checking now that the dependency has been populated
if [ -f "_deps/ogg-src/cmake/CheckSizes.cmake" ]; then
    cat << 'EOF' > "_deps/ogg-src/cmake/CheckSizes.cmake"
set(SIZE16 2)
set(USIZE16 2)
set(SIZE32 4)
set(USIZE32 4)
set(SIZE64 8)
set(USIZE64 8)
EOF
    # Re-run cmake to pick up the patched check
    cmake .. || { exit 1; }
fi

# Build the project core target
make VERBOSE=1 -j $PROC_NR || { exit 1; }

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