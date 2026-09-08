#!/bin/bash
# package.sh

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/geolith-libretro.git"    
REPO_FOLDER="geolith_libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

cd libretro || { exit 1; }

# Patch Makefile to inject zlib search path and force-disable LTO across compilation flags and ar/ranlib tool selection
if [ -f "Makefile" ]; then
    sed -i '/ifeq ($(platform), ps2)/a \    CFLAGS += -I$(PS2SDK)/ports/include -fno-lto\n    CXXFLAGS += -I$(PS2SDK)/ports/include -fno-lto\n    LDFLAGS += -fno-lto\n    AR = mips64r5900el-ps2-elf-ar\n    RANLIB = mips64r5900el-ps2-elf-ranlib' Makefile || true
fi

# Compile core cleanly with LTO disabled entirely
make -j $PROC_NR platform=ps2 LTO=0 USE_LTO=0 || { exit 1; }

## Inspect binary size and sections locally in the script
FOUND_ARCHIVE=$(find . -name "*_ps2.a" | head -n 1)

## Return back to the workspace root
cd .. || { exit 1; }

## Find and copy the generated archive
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*_ps2.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p geolith_libretro
cp -f "$FOUND_ARCHIVE" geolith_libretro/geolith_libretro_ps2.a || { exit 1; }