#!/bin/bash
# package.sh for BennuGD_libretro on PS2
set -e

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/BennuGD_libretro"
REPO_FOLDER="BennuGD_libretro"
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

## Configure using CMake with absolute paths to compiler and archiver for PS2
cmake .. \
    -DCMAKE_SYSTEM_NAME=Generic \
    -DCMAKE_SYSTEM_PROCESSOR=mips \
    -DCMAKE_C_COMPILER=/usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-gcc \
    -DCMAKE_AR=/usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-ar \
    -DCMAKE_RANLIB=/usr/local/ps2dev/ee/bin/mips64r5900el-ps2-elf-ranlib \
    -DCMAKE_BUILD_TYPE=Release || { exit 1; }

# Build explicitly targeting the libretro target sub-component
cmake --build . --target bennugd_libretro -- -j $PROC_NR || { exit 1; }

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